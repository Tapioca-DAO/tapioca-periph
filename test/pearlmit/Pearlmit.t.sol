// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Tapioca
import {Pearlmit, IPearlmit, PearlmitHash} from "tapioca-periph/pearlmit/Pearlmit.sol";
import {PearlmitBaseTest, ERC20Mock, ERC721Mock, ERC1155Mock} from "./PearlmitBase.t.sol";

contract PearlmitTest is PearlmitBaseTest {
    function test_hashBatchTransferFrom() public {
        address erc20Addr = _deployNew20(alice, 1000);

        {
            uint256 nonce = 0; // Can be random, it's unordered
            uint48 sigDeadline = uint48(block.timestamp);
            address executor = alice; // Who is expected execute the permit
            bytes32 hashedData = keccak256("0x"); // Extra data

            // Create approvals + their hashes
            IPearlmit.SignatureApproval[] memory approvals = new IPearlmit.SignatureApproval[](1);
            approvals[0] =
                IPearlmit.SignatureApproval({tokenType: 20, token: erc20Addr, id: 0, amount: 100, operator: bob});
            bytes32[] memory hashApprovals = new bytes32[](1);
            for (uint256 i = 0; i < 1; ++i) {
                hashApprovals[i] = keccak256(
                    abi.encode(
                        PearlmitHash._PERMIT_SIGNATURE_APPROVAL_TYPEHASH,
                        approvals[i].tokenType,
                        approvals[i].token,
                        approvals[i].id,
                        approvals[i].amount,
                        approvals[i].operator
                    )
                );
            }

            // Create batch digest and sign it
            bytes32 digest = ECDSA.toTypedDataHash(
                pearlmit.domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        PearlmitHash._PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                        keccak256(abi.encodePacked(hashApprovals)),
                        nonce,
                        sigDeadline,
                        pearlmit.masterNonce(alice),
                        executor,
                        hashedData
                    )
                )
            );
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);
            bytes memory signedPermit = abi.encodePacked(r, s, v);

            // Execute the permit
            IPearlmit.PermitBatchTransferFrom memory batch = IPearlmit.PermitBatchTransferFrom({
                approvals: approvals,
                owner: alice,
                nonce: nonce,
                sigDeadline: uint48(sigDeadline),
                masterNonce: pearlmit.masterNonce(alice),
                signedPermit: signedPermit,
                executor: executor,
                hashedData: hashedData
            });

            vm.prank(bob); // Can't be called by bob
            vm.expectRevert();
            pearlmit.permitBatchApprove(batch, hashedData);

            vm.prank(executor);
            pearlmit.permitBatchApprove(batch, hashedData);
        }
        // Check the allowance
        {
            (uint256 allowedAmount, uint256 expiration) = pearlmit.allowance(alice, bob, 20, erc20Addr, 0);
            assertEq(allowedAmount, 100);
            assertEq(expiration, block.timestamp);
        }

        // Clear the allowance
        uint256 snapshot = vm.snapshot();
        {
            vm.prank(bob);
            pearlmit.clearAllowance(alice, 20, erc20Addr, 0);
            (uint256 allowedAmount, uint256 expiration) = pearlmit.allowance(alice, bob, 20, erc20Addr, 0);
            assertEq(allowedAmount, 0);
            assertEq(expiration, 0);
        }
        vm.revertTo(snapshot);

        // ERC20 transfer
        {
            ERC20Mock erc20 = ERC20Mock(erc20Addr);
            vm.prank(alice);
            erc20.approve(address(pearlmit), type(uint256).max); // Pearlmit needs to have allowance

            assertEq(erc20.balanceOf(bob), 0);
            vm.prank(bob);
            pearlmit.transferFromERC20(alice, bob, erc20Addr, 100);
            assertEq(erc20.balanceOf(bob), 100);
        }
    }
}
