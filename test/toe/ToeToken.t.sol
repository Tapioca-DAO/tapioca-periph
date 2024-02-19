// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.22;

// LZ
import {
    SendParam,
    MessagingFee,
    MessagingReceipt,
    OFTReceipt
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";

// External
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Tapioca
import {
    ERC721PermitApprovalMsg,
    ERC20PermitApprovalMsg,
    ERC721PermitStruct,
    ERC20PermitStruct,
    RemoteTransferMsg
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {
    ITapiocaOmnichainEngine,
    PrepareLzCallReturn,
    PrepareLzCallData,
    ComposeMsgData,
    LZSendParam
} from "tapioca-periph/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {TapiocaOmnichainExtExec} from "tapioca-periph/tapiocaOmnichainEngine/extension/TapiocaOmnichainExtExec.sol";
import {BaseToeMsgType} from "tapioca-periph/tapiocaOmnichainEngine/BaseToeMsgType.sol";

// Tapioca Tests
import {ToeTestHelper} from "./ToeTestHelper.sol";
import {ToeTokenReceiverMock} from "../mocks/ToeTokenMock/ToeTokenReceiverMock.sol";
import {ToeTokenSenderMock} from "../mocks/ToeTokenMock/ToeTokenSenderMock.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {ToeTokenMock} from "../mocks/ToeTokenMock/ToeTokenMock.sol";
import {Cluster} from "tapioca-periph/Cluster/Cluster.sol";
import {ERC721Mock} from "../mocks/ERC721Mock.sol";

import "forge-std/Test.sol";

// TODO Clean refactor
contract TapTokenTest is ToeTestHelper, BaseToeMsgType {
    using OptionsBuilder for bytes;
    using OFTMsgCodec for bytes32;
    using OFTMsgCodec for bytes;

    uint32 aEid = 1;
    uint32 bEid = 2;

    ToeTokenMock aToeOFT;
    ToeTokenMock bToeOFT;

    ICluster cluster;
    ToeTestHelper toeTestHelper;

    uint256 internal userAPKey = 0x1;
    uint256 internal userBPKey = 0x2;
    address public userA = vm.addr(userAPKey);
    address public userB = vm.addr(userBPKey);
    uint256 public initialBalance = 100 ether;

    /**
     * DEPLOY setup addresses
     */
    address __owner = address(this);
    address __extExec;

    /**
     * @dev TapToken global event checks
     */
    event OFTReceived(bytes32, address, uint256, uint256);
    event ComposeReceived(uint16 indexed msgType, bytes32 indexed guid, bytes composeMsg);

    /**
     * @dev Setup the OApps by deploying them and setting up the endpoints.
     */
    function setUp() public override {
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);
        vm.label(userA, "userA");
        vm.label(userB, "userB");

        setUpEndpoints(3, LibraryType.UltraLightNode);

        cluster = ICluster(address(new Cluster(1, address(__owner))));

        __extExec = address(new TapiocaOmnichainExtExec(cluster, __owner));
        aToeOFT = ToeTokenMock(
            payable(
                _deployOApp(
                    type(ToeTokenMock).creationCode,
                    abi.encode(
                        address(endpoints[aEid]),
                        __owner,
                        __extExec,
                        address(new ToeTokenSenderMock("", "", address(endpoints[aEid]), address(this), address(0))),
                        address(new ToeTokenReceiverMock("", "", address(endpoints[aEid]), address(this), address(0)))
                    )
                )
            )
        );
        vm.label(address(aToeOFT), "aToeOFT");
        bToeOFT = ToeTokenMock(
            payable(
                _deployOApp(
                    type(ToeTokenMock).creationCode,
                    abi.encode(
                        address(endpoints[bEid]),
                        __owner,
                        address(__extExec),
                        address(new ToeTokenSenderMock("", "", address(endpoints[bEid]), address(this), address(0))),
                        address(new ToeTokenReceiverMock("", "", address(endpoints[bEid]), address(this), address(0)))
                    )
                )
            )
        );
        vm.label(address(bToeOFT), "bToeOFT");

        toeTestHelper = new ToeTestHelper();

        // config and wire the ofts
        address[] memory ofts = new address[](2);
        ofts[0] = address(aToeOFT);
        ofts[1] = address(bToeOFT);
        this.wireOApps(ofts);
    }

    /**
     * Allocation:
     * ============
     * DSO: 53,313,405
     * DAO: 8m
     * Contributors: 15m
     * Early supporters: 3,686,595
     * Supporters: 12.5m
     * LBP: 5m
     * Airdrop: 2.5m
     * == 100M ==
     */
    function test_constructor() public {
        // A tests
        assertEq(aToeOFT.owner(), address(this));
        assertEq(aToeOFT.token(), address(aToeOFT));
        assertEq(address(aToeOFT.endpoint()), address(endpoints[aEid]));

        // B tests
        assertEq(bToeOFT.owner(), address(this));
        assertEq(bToeOFT.token(), address(bToeOFT));
        assertEq(address(bToeOFT.endpoint()), address(endpoints[bEid]));
    }

    function test_erc20_permit() public {
        ERC20PermitStruct memory permit_ =
            ERC20PermitStruct({owner: userA, spender: userB, value: 1e18, nonce: 0, deadline: 1 days});

        bytes32 digest_ = aToeOFT.getTypedDataHash(permit_);
        ERC20PermitApprovalMsg memory permitApproval_ =
            __getERC20PermitData(permit_, digest_, address(aToeOFT), userAPKey);

        aToeOFT.permit(
            permit_.owner,
            permit_.spender,
            permit_.value,
            permit_.deadline,
            permitApproval_.v,
            permitApproval_.r,
            permitApproval_.s
        );
        assertEq(aToeOFT.allowance(userA, userB), 1e18);
        assertEq(aToeOFT.nonces(userA), 1);
    }

    // TODO Update using mocks instead of twTap
    // function test_erc721_permit() public {
    //     ERC721Mock erc721Mock = new ERC721Mock("Mock", "Mock");
    //     vm.label(address(erc721Mock), "erc721Mock");
    //     erc721Mock.mint(address(userA), 1);

    //     ERC721PermitStruct memory permit_ = ERC721PermitStruct({spender: userB, tokenId: 1, nonce: 0, deadline: 1 days});

    //     bytes32 digest_ = erc721Mock.getTypedDataHash(permit_);
    //     ERC721PermitApprovalMsg memory permitApproval_ =
    //         __getERC721PermitData(permit_, digest_, address(erc721Mock), userAPKey);

    //     erc721Mock.permit(
    //         permit_.spender, permit_.tokenId, permit_.deadline, permitApproval_.v, permitApproval_.r, permitApproval_.s
    //     );
    //     assertEq(erc721Mock.getApproved(1), userB);
    //     assertEq(erc721Mock.nonces(userA), 1);
    // }

    /**
     * ERC20 APPROVALS
     */
    // TODO Update using mocks instead of twTap
    // function test_toeOFT_erc20_approvals() public {
    //     address userC_ = vm.addr(0x3);

    //     ERC20PermitApprovalMsg memory permitApprovalB_;
    //     ERC20PermitApprovalMsg memory permitApprovalC_;
    //     bytes memory approvalsMsg_;

    //     {
    //         ERC20PermitStruct memory approvalUserB_ =
    //             ERC20PermitStruct({owner: userA, spender: userB, value: 1e18, nonce: 0, deadline: 1 days});
    //         ERC20PermitStruct memory approvalUserC_ = ERC20PermitStruct({
    //             owner: userA,
    //             spender: userC_,
    //             value: 2e18,
    //             nonce: 1, // Nonce is 1 because we already called permit() on userB
    //             deadline: 2 days
    //         });

    //         permitApprovalB_ = __getERC20PermitData(
    //             approvalUserB_, bToeOFT.getTypedDataHash(approvalUserB_), address(bToeOFT), userAPKey
    //         );

    //         permitApprovalC_ = __getERC20PermitData(
    //             approvalUserC_, bToeOFT.getTypedDataHash(approvalUserC_), address(bToeOFT), userAPKey
    //         );

    //         ERC20PermitApprovalMsg[] memory approvals_ = new ERC20PermitApprovalMsg[](2);
    //         approvals_[0] = permitApprovalB_;
    //         approvals_[1] = permitApprovalC_;

    //         approvalsMsg_ = toeTestHelper.encodeERC20PermitApprovalMsg(approvals_);
    //     }

    //     PrepareLzCallReturn memory prepareLzCallReturn_ = toeTestHelper.prepareLzCall(
    //         ITapToken(address(aToeOFT)),
    //         PrepareLzCallData({
    //             dstEid: bEid,
    //             recipient: OFTMsgCodec.addressToBytes32(address(this)),
    //             amountToSendLD: 0,
    //             minAmountToCreditLD: 0,
    //             msgType: MSG_APPROVALS,
    //             composeMsgData: ComposeMsgData({
    //                 index: 0,
    //                 gas: 1_000_000,
    //                 value: 0,
    //                 data: approvalsMsg_,
    //                 prevData: bytes(""),
    //                 prevOptionsData: bytes("")
    //             }),
    //             lzReceiveGas: 1_000_000,
    //             lzReceiveValue: 0
    //         })
    //     );
    //     bytes memory composeMsg_ = prepareLzCallReturn_.composeMsg;
    //     bytes memory oftMsgOptions_ = prepareLzCallReturn_.oftMsgOptions;
    //     MessagingFee memory msgFee_ = prepareLzCallReturn_.msgFee;
    //     LZSendParam memory lzSendParam_ = prepareLzCallReturn_.lzSendParam;

    //     (MessagingReceipt memory msgReceipt_,) = aToeOFT.sendPacket{value: msgFee_.nativeFee}(lzSendParam_, composeMsg_);

    //     verifyPackets(uint32(bEid), address(bToeOFT));

    //     vm.expectEmit(true, true, true, false);
    //     emit IERC20.Approval(userA, userB, 1e18);

    //     vm.expectEmit(true, true, true, false);
    //     emit IERC20.Approval(userA, userC_, 1e18);

    //     __callLzCompose(
    //         LzOFTComposedData(
    //             MSG_APPROVALS,
    //             msgReceipt_.guid,
    //             composeMsg_,
    //             bEid,
    //             address(bToeOFT), // Compose creator (at lzReceive)
    //             address(bToeOFT), // Compose receiver (at lzCompose)
    //             address(this),
    //             oftMsgOptions_
    //         )
    //     );

    //     assertEq(bToeOFT.allowance(userA, userB), 1e18);
    //     assertEq(bToeOFT.allowance(userA, userC_), 2e18);
    //     assertEq(bToeOFT.nonces(userA), 2);
    // }

    /**
     * ERC721 APPROVALS
     */
    // TODO Update using mocks instead of twTap
    // function test_toeOFT_erc721_approvals() public {
    //     address userC_ = vm.addr(0x3);
    //     // Mint tokenId
    //     {
    //         deal(address(bToeOFT), address(userA), 1e18);
    //         deal(address(bToeOFT), address(userB), 1e18);

    //         vm.startPrank(userA);
    //         bToeOFT.approve(address(twTap), 1e18);
    //         twTap.participate(address(userA), 1e18, 1 weeks);

    //         vm.startPrank(userB);
    //         bToeOFT.approve(address(twTap), 1e18);
    //         twTap.participate(address(userB), 1e18, 1 weeks);
    //         vm.stopPrank();
    //     }

    //     ERC721PermitApprovalMsg memory permitApprovalB_;
    //     ERC721PermitApprovalMsg memory permitApprovalC_;
    //     bytes memory approvalsMsg_;

    //     {
    //         ERC721PermitStruct memory approvalUserB_ =
    //             ERC721PermitStruct({spender: userB, tokenId: 1, nonce: 0, deadline: 1 days});
    //         ERC721PermitStruct memory approvalUserC_ =
    //             ERC721PermitStruct({spender: userC_, tokenId: 2, nonce: 0, deadline: 1 days});

    //         permitApprovalB_ =
    //             __getERC721PermitData(approvalUserB_, twTap.getTypedDataHash(approvalUserB_), address(twTap), userAPKey);

    //         permitApprovalC_ =
    //             __getERC721PermitData(approvalUserC_, twTap.getTypedDataHash(approvalUserC_), address(twTap), userBPKey);

    //         ERC721PermitApprovalMsg[] memory approvals_ = new ERC721PermitApprovalMsg[](2);
    //         approvals_[0] = permitApprovalB_;
    //         approvals_[1] = permitApprovalC_;

    //         approvalsMsg_ = toeTestHelper.encodeERC721PermitApprovalMsg(approvals_);
    //     }

    //     PrepareLzCallReturn memory prepareLzCallReturn_ = toeTestHelper.prepareLzCall(
    //         ITapiocaOmnichainEngine(address(aToeOFT)),
    //         PrepareLzCallData({
    //             dstEid: bEid,
    //             recipient: OFTMsgCodec.addressToBytes32(address(this)),
    //             amountToSendLD: 0,
    //             minAmountToCreditLD: 0,
    //             msgType: MSG_NFT_APPROVALS,
    //             composeMsgData: ComposeMsgData({
    //                 index: 0,
    //                 gas: 1_000_000,
    //                 value: 0,
    //                 data: approvalsMsg_,
    //                 prevData: bytes(""),
    //                 prevOptionsData: bytes("")
    //             }),
    //             lzReceiveGas: 1_000_000,
    //             lzReceiveValue: 0
    //         })
    //     );
    //     bytes memory composeMsg_ = prepareLzCallReturn_.composeMsg;
    //     bytes memory oftMsgOptions_ = prepareLzCallReturn_.oftMsgOptions;
    //     MessagingFee memory msgFee_ = prepareLzCallReturn_.msgFee;
    //     LZSendParam memory lzSendParam_ = prepareLzCallReturn_.lzSendParam;

    //     (MessagingReceipt memory msgReceipt_,) = aToeOFT.sendPacket{value: msgFee_.nativeFee}(lzSendParam_, composeMsg_);

    //     verifyPackets(uint32(bEid), address(bToeOFT));

    //     vm.expectEmit(true, true, true, false);
    //     emit IERC721.Approval(userA, userB, 1);

    //     vm.expectEmit(true, true, true, false);
    //     emit IERC721.Approval(userB, userC_, 2);

    //     __callLzCompose(
    //         LzOFTComposedData(
    //             MSG_NFT_APPROVALS,
    //             msgReceipt_.guid,
    //             composeMsg_,
    //             bEid,
    //             address(bToeOFT), // Compose creator (at lzReceive)
    //             address(bToeOFT), // Compose receiver (at lzCompose)
    //             address(this),
    //             oftMsgOptions_
    //         )
    //     );

    //     assertEq(twTap.getApproved(1), userB);
    //     assertEq(twTap.getApproved(2), userC_);
    //     assertEq(twTap.nonces(userA), 1);
    //     assertEq(twTap.nonces(userB), 1);
    // }

    /**
     * =================
     *      HELPERS
     * =================
     */

    /**
     * @dev Used to bypass stack too deep
     *
     * @param msgType The message type of the lz Compose.
     * @param guid The message GUID.
     * @param composeMsg The source raw OApp compose message. If compose msg is composed with other msgs,
     * the msg should contain only the compose msg at its index and forward. I.E composeMsg[currentIndex:]
     * @param dstEid The destination EID.
     * @param from The address initiating the composition, typically the OApp where the lzReceive was called.
     * @param to The address of the lzCompose receiver.
     * @param srcMsgSender The address of src EID OFT `msg.sender` call initiator .
     * @param extraOptions The options passed in the source OFT call. Only restriction is to have it contain the actual compose option for the index,
     * whether there are other composed calls or not.
     */
    struct LzOFTComposedData {
        uint16 msgType;
        bytes32 guid;
        bytes composeMsg;
        uint32 dstEid;
        address from;
        address to;
        address srcMsgSender;
        bytes extraOptions;
    }

    /**
     * @notice Call lzCompose on the destination OApp.
     *
     * @dev Be sure to verify the message by calling `TestHelper.verifyPackets()`.
     * @dev Will internally verify the emission of the `ComposeReceived` event with
     * the right msgType, GUID and lzReceive composer message.
     *
     * @param _lzOFTComposedData The data to pass to the lzCompose call.
     */
    function __callLzCompose(LzOFTComposedData memory _lzOFTComposedData) internal {
        vm.expectEmit(true, true, true, false);
        emit ComposeReceived(_lzOFTComposedData.msgType, _lzOFTComposedData.guid, _lzOFTComposedData.composeMsg);

        this.lzCompose(
            _lzOFTComposedData.dstEid,
            _lzOFTComposedData.from,
            _lzOFTComposedData.extraOptions,
            _lzOFTComposedData.guid,
            _lzOFTComposedData.to,
            abi.encodePacked(
                OFTMsgCodec.addressToBytes32(_lzOFTComposedData.srcMsgSender), _lzOFTComposedData.composeMsg
            )
        );
    }
}
