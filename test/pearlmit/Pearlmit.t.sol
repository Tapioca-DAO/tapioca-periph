// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Tapioca
import {Pearlmit, IPearlmit, PearlmitHash, PermitC} from "tapioca-periph/pearlmit/Pearlmit.sol";
import {PearlmitBaseTest, ERC20Mock, ERC721Mock, ERC1155Mock} from "./PearlmitBase.t.sol";
import {console} from "forge-std/console.sol";
import {PearlmitMock} from "../mocks/PearlmitMock.sol";
import {
    PermitC__SignatureTransferExceededPermitExpired,
    PermitC__NonceAlreadyUsedOrRevoked,
    PermitC__SignatureTransferInvalidSignature
} from "permitc/Errors.sol";
import "forge-std/console.sol";

contract PearlmitTest is PearlmitBaseTest {
    PearlmitMock pearlmitMock;

    struct test_hashBatchTransferFrom_MemoryData {
        address erc20Addr;
        address batchOwner;
        uint256 nonce;
        uint48 sigDeadline;
        address executor;
        bytes32 hashedData;
    }

    function test_hashBatchTransferFrom() public {
        address erc20Addr = _deployNew20(alice, 1000);
        test_hashBatchTransferFrom_MemoryData memory data;

        {
            data.batchOwner = alice;
            data.nonce = 0; // Can be random, it's unordered
            data.sigDeadline = uint48(block.timestamp);
            data.executor = address(this); // Who is expected execute the permit
            data.hashedData = keccak256("0x"); // Extra data

            // Create approvals + their hashes
            IPearlmit.SignatureApproval[] memory approvals = new IPearlmit.SignatureApproval[](1);
            approvals[0] =
                IPearlmit.SignatureApproval({tokenType: 20, token: erc20Addr, id: 0, amount: 100, operator: bob});
            bytes32[] memory hashApprovals = new bytes32[](1);
            {
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
            }

            // Create batch digest and sign it
            bytes32 digest = ECDSA.toTypedDataHash(
                pearlmit.domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        PearlmitHash._PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                        keccak256(abi.encodePacked(hashApprovals)),
                        data.batchOwner,
                        data.nonce,
                        data.sigDeadline,
                        pearlmit.masterNonce(data.batchOwner),
                        data.executor,
                        data.hashedData
                    )
                )
            );

            bytes memory signedPermit;
            {
                (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);
                signedPermit = abi.encodePacked(r, s, v);
            }

            // Execute the permit
            IPearlmit.PermitBatchTransferFrom memory batch = IPearlmit.PermitBatchTransferFrom({
                approvals: approvals,
                owner: data.batchOwner,
                nonce: data.nonce,
                sigDeadline: uint48(data.sigDeadline),
                masterNonce: pearlmit.masterNonce(data.batchOwner),
                signedPermit: signedPermit,
                executor: data.executor,
                hashedData: data.hashedData
            });

            vm.prank(bob); // Can't be called by bob
            vm.expectRevert();
            pearlmit.permitBatchApprove(batch, data.hashedData);

            vm.prank(data.executor);
            pearlmit.permitBatchApprove(batch, data.hashedData);
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

    /**
     * @dev Tests `_checkBatchPermitData_` to ensure it reverts for a wrong signature.
     */
    function test_CheckBatchPermitDataRevertForWrongSignature() public useSetup {
        (IPearlmit.PermitBatchTransferFrom memory batch, bytes32 hashedData, bytes32 digest, address erc20Addr) =
            batchApproveErc20ForTests();

        vm.startPrank(alice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobKey, digest);
        bytes memory wrongSignedPermit = abi.encodePacked(r, s, v);
        vm.expectRevert(PermitC__SignatureTransferInvalidSignature.selector);
        pearlmitMock.checkBatchPermitData_(batch.nonce, batch.sigDeadline, alice, hashedData, wrongSignedPermit);
    }

    /**
     * @dev Tests `_checkPermitBatchApproval` to ensure it reverts for bad hashed data.
     */
    function test_RevertForBadHashedData() public useSetup {
        (IPearlmit.PermitBatchTransferFrom memory batch,,,) = batchApproveErc20ForTests();
        bytes32 badHashedData = "0x23";
        vm.startPrank(alice);
        vm.expectRevert(Pearlmit.Pearlmit__BadHashedData.selector);

        pearlmitMock.checkPermitBatchApproval_(batch, badHashedData);
    }

    /**
     * @dev Tests `_checkBatchPermitData` to ensure it reverts for an expired permit.
     */
    function test_PermitDataRevertForPermitExpired() public useSetup {
        (IPearlmit.PermitBatchTransferFrom memory batch,, bytes32 digest,) = batchApproveErc20ForTests();
        vm.startPrank(alice);
        vm.warp(block.timestamp + 1 days); // Move the block timestamp forward by 1 day
        vm.expectRevert(PermitC__SignatureTransferExceededPermitExpired.selector);
        pearlmitMock.checkBatchPermitData_(batch.nonce, batch.sigDeadline, batch.owner, digest, batch.signedPermit);
    }
    /**
     * @dev Tests `_checkBatchPermitData_` to ensure it reverts for an invalidated nonce.
     */

    function test_RevertForInvalidatedNonce() public useSetup {
        (IPearlmit.PermitBatchTransferFrom memory batch,, bytes32 digest,) = batchApproveErc20ForTests();
        vm.startPrank(alice);
        pearlmitMock.checkBatchPermitData_(batch.nonce, batch.sigDeadline, batch.owner, digest, batch.signedPermit);
        vm.expectRevert(PermitC__NonceAlreadyUsedOrRevoked.selector);
        pearlmitMock.checkBatchPermitData_(batch.nonce, batch.sigDeadline, batch.owner, digest, batch.signedPermit);
    }

    /**
     * @dev Tests `permitBatchApprove` for approving ERC721 and ERC1155 tokens.
     */
    function test_PermitBatchApproveErc721andErc1155() public {
        (
            IPearlmit.PermitBatchTransferFrom memory batch,
            address erc721Addr,
            address erc1155Addr,
            IPearlmit.SignatureApproval[] memory approvals
        ) = batchApproveErc721AndErc1155ForTest();
        pearlmit.permitBatchApprove(batch, batch.hashedData);

        //checks for ERC721
        (uint256 allowedAmountErc721Carol, uint256 expirationErc721Carol) =
            pearlmit.allowance(alice, carol, 721, erc721Addr, 1);
        assertEq(allowedAmountErc721Carol, 0);
        assertEq(expirationErc721Carol, 0);

        (uint256 allowedAmountErc721Bob, uint256 expirationErc721Bob) =
            pearlmit.allowance(alice, bob, 721, erc721Addr, 1);
        assertEq(allowedAmountErc721Bob, approvals[0].amount);
        assertEq(expirationErc721Bob, batch.sigDeadline);

        //checks for ERC1155
        (uint256 allowedAmounterc1155Bob, uint256 expiration1155Bob) =
            pearlmit.allowance(alice, bob, 1155, erc1155Addr, 1);
        assertEq(allowedAmounterc1155Bob, 0);
        assertEq(expiration1155Bob, 0);

        (uint256 allowedAmounterc1155Carol, uint256 expiration1155Carol) =
            pearlmit.allowance(alice, carol, 1155, erc1155Addr, 1);
        assertEq(allowedAmounterc1155Carol, approvals[1].amount);
        assertEq(expiration1155Carol, batch.sigDeadline);
    }

    /**
     * @dev Helper function to create batch approval for ERC20 tokens for tests.
     * @return The batch permit, hashed data, digest, and ERC20 token address.
     */
    function batchApproveErc20ForTests()
        public
        returns (IPearlmit.PermitBatchTransferFrom memory, bytes32, bytes32, address)
    {
        address erc20Addr = _deployNew20(alice, 1000);
        uint256 nonce = 0;
        uint48 sigDeadline = uint48(block.timestamp);
        bytes32 hashedData = keccak256("0x");
        IPearlmit.SignatureApproval[] memory approvals = new IPearlmit.SignatureApproval[](1);
        approvals[0] = IPearlmit.SignatureApproval({tokenType: 20, token: erc20Addr, id: 0, amount: 100, operator: bob});
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

        bytes32 digest = ECDSA.toTypedDataHash(
            pearlmitMock.domainSeparatorV4(),
            keccak256(
                abi.encode(
                    PearlmitHash._PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                    keccak256(abi.encodePacked(hashApprovals)),
                    alice,
                    nonce,
                    sigDeadline,
                    pearlmitMock.masterNonce(alice),
                    alice,
                    hashedData
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);
        bytes memory signedPermit = abi.encodePacked(r, s, v);

        IPearlmit.PermitBatchTransferFrom memory batch = IPearlmit.PermitBatchTransferFrom({
            approvals: approvals,
            owner: alice,
            nonce: nonce,
            sigDeadline: uint48(sigDeadline),
            masterNonce: pearlmitMock.masterNonce(alice),
            signedPermit: signedPermit,
            executor: alice,
            hashedData: hashedData
        });

        return (batch, hashedData, digest, erc20Addr);
    }

    /**
     * @dev Tests `clearAllowance` to ensure it clears the allowance correctly on two different operator "Bob" and "Carol".
     */
    function test_ClearAllowance() public {
        (
            IPearlmit.PermitBatchTransferFrom memory batch,
            address erc721Addr,
            address erc1155Addr,
            IPearlmit.SignatureApproval[] memory approvals
        ) = batchApproveErc721AndErc1155ForTest();
        pearlmit.permitBatchApprove(batch, batch.hashedData);
        uint256 allowedAmountErc721Bob;
        uint256 expirationErc721Bob;

        vm.startPrank(alice); //called by the owner
        pearlmit.clearAllowance(alice, 721, erc721Addr, 1);
        (allowedAmountErc721Bob, expirationErc721Bob) = pearlmit.allowance(alice, bob, 721, erc721Addr, 1);

        assertEq(allowedAmountErc721Bob, approvals[0].amount);
        assertEq(expirationErc721Bob, batch.sigDeadline);
        vm.stopPrank();

        vm.startPrank(bob); //called by the operator
        pearlmit.clearAllowance(alice, 721, erc721Addr, 1);
        (allowedAmountErc721Bob, expirationErc721Bob) = pearlmit.allowance(alice, bob, 721, erc721Addr, 1);
        assertEq(allowedAmountErc721Bob, 0);
        assertEq(expirationErc721Bob, 0);
        vm.stopPrank();

        vm.startPrank(carol); //called by the operator
        pearlmit.clearAllowance(alice, 1155, erc1155Addr, 1);
        (uint256 allowedAmountErc1155Alice, uint256 expirationErc1155Alice) =
            pearlmit.allowance(alice, carol, 1155, erc1155Addr, 1);
        assertEq(allowedAmountErc1155Alice, 0);
        assertEq(expirationErc1155Alice, 0);
        vm.stopPrank();
    }
    /**
     * @dev Helper function to create batch approval for ERC721 and ERC1155 tokens for tests.
     * @return The batch permit, ERC721 token address, ERC1155 token address, and array of approvals.
     */

    function batchApproveErc721AndErc1155ForTest()
        public
        returns (IPearlmit.PermitBatchTransferFrom memory, address, address, IPearlmit.SignatureApproval[] memory)
    {
        address erc721Addr = _deployNew721(alice, 1);
        address erc1155Addr = _deployNew1155(alice, 1, 1000);

        test_hashBatchTransferFrom_MemoryData memory data;

        data.batchOwner = alice;
        data.nonce = 0;
        data.sigDeadline = uint48(block.timestamp);
        data.executor = address(this);
        data.hashedData = keccak256("0x");

        // Create approvals + their hashes
        IPearlmit.SignatureApproval[] memory approvals = new IPearlmit.SignatureApproval[](2);
        approvals[0] = IPearlmit.SignatureApproval({tokenType: 721, token: erc721Addr, id: 1, amount: 1, operator: bob});
        approvals[1] =
            IPearlmit.SignatureApproval({tokenType: 1155, token: erc1155Addr, id: 1, amount: 1000, operator: carol});
        bytes32[] memory hashApprovals = new bytes32[](approvals.length);
        {
            for (uint256 i = 0; i < approvals.length; ++i) {
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
        }

        // Create batch digest and sign it
        bytes32 digest = ECDSA.toTypedDataHash(
            pearlmit.domainSeparatorV4(),
            keccak256(
                abi.encode(
                    PearlmitHash._PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                    keccak256(abi.encodePacked(hashApprovals)),
                    data.batchOwner,
                    data.nonce,
                    data.sigDeadline,
                    pearlmit.masterNonce(data.batchOwner),
                    data.executor,
                    data.hashedData
                )
            )
        );

        bytes memory signedPermit;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);
            signedPermit = abi.encodePacked(r, s, v);
        }

        // Execute the permit
        IPearlmit.PermitBatchTransferFrom memory batch = IPearlmit.PermitBatchTransferFrom({
            approvals: approvals,
            owner: data.batchOwner,
            nonce: data.nonce,
            sigDeadline: uint48(data.sigDeadline),
            masterNonce: pearlmit.masterNonce(data.batchOwner),
            signedPermit: signedPermit,
            executor: data.executor,
            hashedData: data.hashedData
        });
        return (batch, erc721Addr, erc1155Addr, approvals);
    }

    modifier useSetup() {
        pearlmitMock = new PearlmitMock();
        _;
    }
}
