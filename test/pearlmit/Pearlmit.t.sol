// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Tapioca
import {Pearlmit, IPearlmit, PearlmitHash} from "tapioca-periph/pearlmit/Pearlmit.sol";
import {PearlmitBaseTest, ERC20Mock, ERC721Mock, ERC1155Mock} from "./PearlmitBase.t.sol";

contract PearlmitTest is PearlmitBaseTest {
    function testPermitBatchTransferFrom() public {
        // Deploy ERC20, ERC721, and ERC1155 tokens and mint some tokens.
        address erc20Token = _deployNew20(alice, 1e18);
        address erc721Token = _deployNew721(alice, 10);
        address erc1155Token = _deployNew1155(alice, 20, 5);

        // Approve Pearlmit to be operator
        {
            vm.startPrank(alice);
            ERC20Mock(erc20Token).approve(address(pearlmit), type(uint256).max);
            ERC721Mock(erc721Token).setApprovalForAll(address(pearlmit), true);
            ERC1155Mock(erc1155Token).setApprovalForAll(address(pearlmit), true);
            vm.stopPrank();
        }

        uint256 sigDeadline = INITIAL_TIMESTAMP + 1000;
        uint256 nonce = 0;
        IPearlmit.PermitBatchTransferFrom memory batchData;
        // Prepare the permit batch transfer from data.

        IPearlmit.SignatureApproval[] memory signatureApprovals = new IPearlmit.SignatureApproval[](3);
        {
            signatureApprovals[0] = IPearlmit.SignatureApproval({
                tokenType: uint8(IPearlmit.TokenType.ERC20),
                token: erc20Token,
                id: 0,
                amount: 1e18,
                operator: bob
            });
            // signatureApprovals[1] = IPearlmit.SignatureApproval({
            //     tokenType: uint8(IPearlmit.TokenType.ERC721),
            //     token: erc721Token,
            //     id: 10,
            //     amount: 0,
            //     operator: bob
            // });
            // signatureApprovals[2] = IPearlmit.SignatureApproval({
            //     tokenType: uint8(IPearlmit.TokenType.ERC1155),
            //     token: erc1155Token,
            //     id: 20,
            //     amount: 5,
            //     operator: bob
            // });
        }

        // Prepare digest and sign the permit
        {
            bytes32[] memory hashApprovals = new bytes32[](3);
            for (uint256 i = 0; i < 3; ++i) {
                hashApprovals[i] = keccak256(
                    abi.encode(
                        PearlmitHash._PERMIT_SIGNATURE_APPROVAL_TYPEHASH,
                        signatureApprovals[i].tokenType,
                        signatureApprovals[i].token,
                        signatureApprovals[i].id,
                        signatureApprovals[i].amount,
                        signatureApprovals[i].operator
                    )
                );
            }

            bytes32 digest = ECDSA.toTypedDataHash(
                pearlmit.domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        PearlmitHash._PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                        keccak256(abi.encodePacked(hashApprovals)),
                        nonce,
                        sigDeadline,
                        pearlmit.masterNonce(alice),
                        address(this),
                        keccak256("0x")
                    )
                )
            );
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);
            bytes memory signedPermit = abi.encodePacked(r, s, v);

            batchData = IPearlmit.PermitBatchTransferFrom({
                approvals: signatureApprovals,
                owner: alice,
                nonce: nonce,
                sigDeadline: uint48(sigDeadline),
                signedPermit: signedPermit,
                executor: address(this),
                hashedData: keccak256("0x")
            });
            //batchData.hashedData = PearlmitHash.hashBatchTransferFrom(batchData, pearlmit.masterNonce(bob));
        }

        // Assert initial state
        assertEq(ERC20Mock(erc20Token).balanceOf(bob), 0);
        assertEq(ERC20Mock(erc20Token).balanceOf(alice), 1e18);
        // assertEq(ERC721Mock(erc721Token).ownerOf(10), alice);
        // assertEq(ERC1155Mock(erc1155Token).balanceOf(alice, 20), 5);
        // assertEq(ERC1155Mock(erc1155Token).balanceOf(bob, 20), 0);

        // Execute the permit batch transfer from
        vm.startPrank(bob);
        vm.expectRevert(); // Revert because executor is different
        pearlmit.permitBatchTransferFrom(batchData, keccak256("0x"));
        vm.stopPrank();

        // Doesn't revert because executor is address(this)
        pearlmit.permitBatchTransferFrom(batchData, keccak256("0x"));

        // Assert final state
        assertEq(ERC20Mock(erc20Token).balanceOf(bob), 1e18);
        assertEq(ERC20Mock(erc20Token).balanceOf(alice), 0);
        // assertEq(ERC721Mock(erc721Token).ownerOf(10), bob);
        // assertEq(ERC1155Mock(erc1155Token).balanceOf(alice, 20), 0);
        // assertEq(ERC1155Mock(erc1155Token).balanceOf(bob, 20), 5);
    }
}
