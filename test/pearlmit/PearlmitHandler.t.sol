// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Tapioca
import {Pearlmit, IPearlmit, PearlmitHash} from "tapioca-periph/pearlmit/Pearlmit.sol";
import {PearlmitBaseTest, ERC20Mock, ERC721Mock, ERC1155Mock} from "./PearlmitBase.t.sol";
import {console} from "forge-std/console.sol";
import {PearlmitHandlerMock} from "../mocks/PearlmitHandlerMock.sol";

contract PearlmitHandlerTest is PearlmitBaseTest {
    PearlmitHandlerMock pearlmitHandlerMock;

    struct test_hashBatchTransferFrom_MemoryData {
        address erc20Addr;
        address batchOwner;
        uint256 nonce;
        uint48 sigDeadline;
        address executor;
        bytes32 hashedData;
    }

    function test_isERC721Approved() public usePearlmitHandlerMock {
        address erc721Addr = _deployNew721(alice, 1);
        bool isAllowed = pearlmitHandlerMock.isERC721Approved_(alice, bob, erc721Addr, 1);
        assertEq(isAllowed, false);

        test_hashBatchTransferFrom_MemoryData memory data;
        {
            data.batchOwner = alice;
            data.nonce = 0;
            data.sigDeadline = uint48(block.timestamp);
            data.executor = address(this);
            data.hashedData = keccak256("0x");

            IPearlmit.SignatureApproval[] memory approvals = new IPearlmit.SignatureApproval[](1);
            approvals[0] =
                IPearlmit.SignatureApproval({tokenType: 721, token: erc721Addr, id: 1, amount: 1, operator: bob});
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

            vm.startPrank(data.executor);
            pearlmit.permitBatchApprove(batch, data.hashedData);
            isAllowed = pearlmitHandlerMock.isERC721Approved_(alice, bob, erc721Addr, 1);
            assertEq(isAllowed, true);
        }
    }

    function test_isERC20Approved() public usePearlmitHandlerMock {
        address erc20Addr = _deployNew20(alice, 1000);
        bool isAllowed;
        isAllowed = pearlmitHandlerMock.isERC20Approved_(alice, bob, erc20Addr, 20);
        assertEq(isAllowed, false);

        test_hashBatchTransferFrom_MemoryData memory data;
        {
            data.batchOwner = alice;
            data.nonce = 0;
            data.sigDeadline = uint48(block.timestamp);
            data.executor = address(this);
            data.hashedData = keccak256("0x");

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

            vm.startPrank(data.executor);
            pearlmit.permitBatchApprove(batch, data.hashedData);
        }
        isAllowed = pearlmitHandlerMock.isERC20Approved_(alice, bob, erc20Addr, 20);
        assertEq(isAllowed, true);
    }

    function test_setPearlmit() public usePearlmitHandlerMock {
        address newIPearlmitAdd = makeAddr("newIPearlmitAdd");
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        pearlmitHandlerMock.setPearlmit(IPearlmit(address(newIPearlmitAdd)));

        vm.stopPrank();
        vm.startPrank(address(this)); // the actual owner

        IPearlmit oldIPearlmit = pearlmitHandlerMock.pearlmit();

        pearlmitHandlerMock.setPearlmit(IPearlmit(address(newIPearlmitAdd)));
        IPearlmit newIPearlmit = pearlmitHandlerMock.pearlmit();

        assertEq(address(newIPearlmit), address(pearlmitHandlerMock.pearlmit()));
        assertNotEq(address(newIPearlmit), address(oldIPearlmit));
    }

    

    modifier usePearlmitHandlerMock() {
        pearlmitHandlerMock = new PearlmitHandlerMock(IPearlmit(address(pearlmit)));

        _;
    }
}

/* 
    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration)
        external;

*/
