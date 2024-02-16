// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

// LZ
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

// Tapioca
import {
    YieldBoxApproveAllMsg,
    MarketPermitActionMsg,
    YieldBoxApproveAssetMsg
} from "tapioca-periph/interfaces/oft/ITOFT.sol";
import {
    ITapiocaOmnichainEngine,
    ERC20PermitApprovalMsg,
    ERC721PermitApprovalMsg,
    LZSendParam,
    RemoteTransferMsg
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

library TapiocaOmnichainEngineCodec {
    /**
     * @dev Option Builder offsets
     *
     * @dev !!!! The options are prepend by the `OptionBuilder.newOptions()` IF it's the first option.
     *
     * ------------------------------------------------------------- *
     * Name            | type     | start | end                      *
     * ------------------------------------------------------------- *
     * NEW_OPTION      | uint16   | 0     | 2                        *
     * ------------------------------------------------------------- *
     *
     * Single option structure, see `OptionsBuilder.addExecutorLzComposeOption`
     * ------------------------------------------------------------- *
     * Name            | type     | start | end  | comment           *
     * ------------------------------------------------------------- *
     * WORKER_ID       | uint8    | 2     | 3    |                   *
     * ------------------------------------------------------------- *
     * OPTION_LENGTH   | uint16   | 3     | 5    |                   *
     * ------------------------------------------------------------- *
     * OPTION_TYPE     | uint8    | 5     | 6    |                   *
     * ------------------------------------------------------------- *
     * INDEX           | uint16   | 6     | 8    |                   *
     * ------------------------------------------------------------- *
     * GAS             | uint128  | 8     | 24   |                   *
     * ------------------------------------------------------------- *
     * VALUE           | uint128  | 24    | 40   | Can be not packed *
     * ------------------------------------------------------------- *
     */
    uint16 internal constant OP_BLDR_EXECUTOR_WORKER_ID_ = 1; // ExecutorOptions.WORKER_ID
    uint16 internal constant OP_BLDR_WORKER_ID_OFFSETS = 2;
    uint16 internal constant OP_BLDR_OPTION_LENGTH_OFFSET = 3;
    uint16 internal constant OP_BLDR_OPTIONS_TYPE_OFFSET = 5;
    uint16 internal constant OP_BLDR_INDEX_OFFSET = 6;
    uint16 internal constant OP_BLDR_GAS_OFFSET = 8;
    uint16 internal constant OP_BLDR_VALUE_OFFSET = 24;

    // LZ message offsets
    uint8 internal constant LZ_COMPOSE_SENDER = 32;

    // TapToken receiver message offsets
    uint8 internal constant MSG_TYPE_OFFSET = 2;
    uint8 internal constant MSG_LENGTH_OFFSET = 4;
    uint8 internal constant MSG_INDEX_OFFSET = 6;

    /**
     *
     * @param _msgType The message type, either custom ones with `PT_` as a prefix, or default OFT ones.
     * @param _msgIndex The index of the compose message to encode.
     * @param _msg The Tap composed message.
     * @return _tapComposedMsg The encoded message. Empty bytes if it's the end of compose message.
     */
    function encodeToeComposeMsg(bytes memory _msg, uint16 _msgType, uint16 _msgIndex, bytes memory _tapComposedMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_tapComposedMsg, _msgType, uint16(_msg.length), _msgIndex, _msg);
    }

    /**
     * @notice Decodes a TapToken composed message. Used by the TapToken receiver.
     *
     *           *    TapToken message packet   *
     * ------------------------------------------------------------- *
     * Name          | type      | start | end                       *
     * ------------------------------------------------------------- *
     * msgType       | uint16    | 0     | 2                         *
     * ------------------------------------------------------------- *
     * msgLength     | uint16    | 2     | 4                         *
     * ------------------------------------------------------------- *
     * msgIndex      | uint16    | 4     | 6                         *
     * ------------------------------------------------------------- *
     * tapComposeMsg | bytes     | 6     | msglength + 6             *
     * ------------------------------------------------------------- *
     *
     * @param _msg The composed message for the send() operation.
     * @return msgType_ The message type. (TapOFT proprietary `PT_` packets or LZ defaults).
     * @return msgLength_ The length of the message.
     * @return msgIndex_ The index of the current message.
     * @return tapComposeMsg_ The TapOFT composed message, which is the actual message.
     * @return nextMsg_ The next composed message. If the message is not composed, it'll be empty.
     */
    function decodeToeComposeMsg(bytes memory _msg)
        internal
        pure
        returns (
            uint16 msgType_,
            uint16 msgLength_,
            uint16 msgIndex_,
            bytes memory tapComposeMsg_,
            bytes memory nextMsg_
        )
    {
        // TODO use bitwise operators?
        msgType_ = BytesLib.toUint16(BytesLib.slice(_msg, 0, 2), 0);
        msgLength_ = BytesLib.toUint16(BytesLib.slice(_msg, MSG_TYPE_OFFSET, 2), 0);

        msgIndex_ = BytesLib.toUint16(BytesLib.slice(_msg, MSG_LENGTH_OFFSET, 2), 0);
        tapComposeMsg_ = BytesLib.slice(_msg, MSG_INDEX_OFFSET, msgLength_);

        uint256 tapComposeOffset_ = MSG_INDEX_OFFSET + msgLength_;
        nextMsg_ = BytesLib.slice(_msg, tapComposeOffset_, _msg.length - (tapComposeOffset_));
    }

    /**
     * @notice Decodes the index of a TapToken composed message.
     *
     * @param _msg The composed message for the send() operation.
     * @return msgIndex_ The index of the current message.
     */
    function decodeIndexOfToeComposeMsg(bytes memory _msg) internal pure returns (uint16 msgIndex_) {
        return BytesLib.toUint16(BytesLib.slice(_msg, MSG_LENGTH_OFFSET, 2), 0);
    }

    /**
     * @notice Decodes the next message of a TapToken composed message, if any.
     * @param _msg The composed message for the send() operation.
     * @return nextMsg_ The next composed message. If the message is not composed, it'll be empty.
     */
    function decodeNextMsgOfToeCompose(bytes memory _msg) internal pure returns (bytes memory nextMsg_) {
        uint16 msgLength_ = BytesLib.toUint16(BytesLib.slice(_msg, MSG_TYPE_OFFSET, 2), 0);

        uint256 tapComposeOffset_ = MSG_INDEX_OFFSET + msgLength_;
        nextMsg_ = BytesLib.slice(_msg, tapComposeOffset_, _msg.length - (tapComposeOffset_));
    }

    /**
     * @dev Decode LzCompose extra options message built by `OptionBuilder.addExecutorLzComposeOption()`.
     * @dev !!! IMPORTANT !!! It only works for options built only by `OptionBuilder.addExecutorLzComposeOption()`.
     *
     * @dev !!!! The options are prepend by the `OptionBuilder.newOptions()` IF it's the first option.
     * ------------------------------------------------------------- *
     * Name            | type     | start | end                      *
     * ------------------------------------------------------------- *
     * NEW_OPTION      | uint16   | 0     | 2                        *
     * ------------------------------------------------------------- *
     *
     * Single option structure, see `OptionsBuilder.addExecutorLzComposeOption`
     * ------------------------------------------------------------- *
     * Name            | type     | start | end  | comment           *
     * ------------------------------------------------------------- *
     * WORKER_ID       | uint8    | 2     | 3    |                   *
     * ------------------------------------------------------------- *
     * OPTION_LENGTH   | uint16   | 3     | 5    |                   *
     * ------------------------------------------------------------- *
     * OPTION_TYPE     | uint8    | 5     | 6    |                   *
     * ------------------------------------------------------------- *
     * INDEX           | uint16   | 6     | 8    |                   *
     * ------------------------------------------------------------- *
     * GAS             | uint128  | 8     | 24   |                   *
     * ------------------------------------------------------------- *
     * VALUE           | uint128  | 24    | 40   | Can be not packed *
     * ------------------------------------------------------------- *
     *
     * @param _options The extra options to be sanitized.
     */
    function decodeExtraOptions(bytes memory _options)
        internal
        pure
        returns (
            uint16 workerId_,
            uint16 optionLength_,
            uint16 optionType_,
            uint16 index_,
            uint128 gas_,
            uint128 value_,
            bytes memory nextMsg_
        )
    {
        workerId_ = BytesLib.toUint8(BytesLib.slice(_options, OP_BLDR_WORKER_ID_OFFSETS, 1), 0);
        // If the workerId is not decoded correctly, it means option index != 0.
        if (workerId_ != OP_BLDR_EXECUTOR_WORKER_ID_) {
            // add the new options prefix
            _options = abi.encodePacked(OptionsBuilder.newOptions(), _options);
            workerId_ = OP_BLDR_EXECUTOR_WORKER_ID_;
        }

        /// @dev Option length is not the size of the actual `_options`, but the size of the option
        /// starting from `OPTION_TYPE`.
        optionLength_ = BytesLib.toUint16(BytesLib.slice(_options, OP_BLDR_OPTION_LENGTH_OFFSET, 2), 0);
        optionType_ = BytesLib.toUint8(BytesLib.slice(_options, OP_BLDR_OPTIONS_TYPE_OFFSET, 1), 0);
        index_ = BytesLib.toUint16(BytesLib.slice(_options, OP_BLDR_INDEX_OFFSET, 2), 0);
        gas_ = BytesLib.toUint128(BytesLib.slice(_options, OP_BLDR_GAS_OFFSET, 16), 0);

        /// @dev `value_` is not encoded if it's 0, check LZ `OptionBuilder.addExecutorLzComposeOption()`
        /// and `ExecutorOptions.encodeLzComposeOption()` for more info.
        /// 19 = OptionType (1) + Index (8) + Gas (16)
        if (optionLength_ == 19) {
            uint16 nextMsgOffset = OP_BLDR_VALUE_OFFSET; // 24
            if (_options.length > nextMsgOffset) {
                nextMsg_ = BytesLib.slice(_options, nextMsgOffset, _options.length - nextMsgOffset);
            }
        }
        /// 35 = OptionType (1) + Index (8) + Gas (16) + Value (16)
        if (optionLength_ == 35) {
            value_ = BytesLib.toUint128(BytesLib.slice(_options, OP_BLDR_VALUE_OFFSET, 16), 0);

            uint16 nextMsgOffset = OP_BLDR_VALUE_OFFSET + 16; // 24 + 16 = 40
            if (_options.length > nextMsgOffset) {
                nextMsg_ = BytesLib.slice(_options, nextMsgOffset, _options.length - nextMsgOffset);
            }
        }
    }

    /**
     * @notice Decodes an encoded message for the `TOFTReceiver.erc20PermitApprovalReceiver()` operation.
     *
     *                    *   message packet   *
     * ------------------------------------------------------------- *
     * Name          | type      | start | end                       *
     * ------------------------------------------------------------- *
     * token         | address   | 0     | 20                        *
     * ------------------------------------------------------------- *
     * owner         | address   | 20    | 40                        *
     * ------------------------------------------------------------- *
     * spender       | address   | 40    | 60                        *
     * ------------------------------------------------------------- *
     * value         | uint256   | 60    | 92                        *
     * ------------------------------------------------------------- *
     * deadline      | uint256   | 92    | 124                       *
     * ------------------------------------------------------------- *
     * v             | uint8     | 124   | 125                       *
     * ------------------------------------------------------------- *
     * r             | bytes32   | 125   | 157                       *
     * ------------------------------------------------------------- *
     * s             | bytes32   | 157   | 189                       *
     * ------------------------------------------------------------- *
     *
     * @param _msg The encoded message. see `TOFTMsgCodec.buildERC20PermitApprovalMsg()`
     */
    struct __offsets {
        uint8 tokenOffset;
        uint8 ownerOffset;
        uint8 spenderOffset;
        uint8 valueOffset;
        uint8 deadlineOffset;
        uint8 vOffset;
        uint8 rOffset;
        uint8 sOffset;
    }

    /**
     * @notice Encodes the message for the `PT_YB_APPROVE_ASSET` operation.
     */
    function buildYieldBoxPermitAssetMsg(YieldBoxApproveAssetMsg memory _approvalMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _approvalMsg.target,
            _approvalMsg.owner,
            _approvalMsg.spender,
            _approvalMsg.assetId,
            _approvalMsg.deadline,
            _approvalMsg.v,
            _approvalMsg.r,
            _approvalMsg.s,
            _approvalMsg.permit
        );
    }

    function decodeYieldBoxApprovalAssetMsg(bytes memory _msg)
        internal
        pure
        returns (YieldBoxApproveAssetMsg memory approvalMsg_)
    {
        __offsets memory offsets_ = __offsets({
            tokenOffset: 20,
            ownerOffset: 40,
            spenderOffset: 60,
            valueOffset: 92,
            deadlineOffset: 124,
            vOffset: 125,
            rOffset: 157,
            sOffset: 189
        });

        // Decoded data
        address target = BytesLib.toAddress(BytesLib.slice(_msg, 0, offsets_.tokenOffset), 0);
        address owner = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.tokenOffset, 20), 0);
        address spender = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.ownerOffset, 20), 0);
        uint256 value = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.spenderOffset, 32), 0);
        uint256 deadline = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.valueOffset, 32), 0);
        uint8 v = uint8(BytesLib.toUint8(BytesLib.slice(_msg, offsets_.deadlineOffset, 1), 0));
        bytes32 r = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.vOffset, 32), 0);
        bytes32 s = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.rOffset, 32), 0);
        bool permit = _msg[offsets_.sOffset] != 0;

        // Return structured data
        approvalMsg_ = YieldBoxApproveAssetMsg(target, owner, spender, value, deadline, v, r, s, permit);
    }

    /**
     * @dev Decode an array of encoded messages for the `TOFTReceiver.erc20PermitApprovalReceiver()` operation.
     * @dev The message length must be a multiple of 189.
     *
     * @param _msg The encoded message. see `TOFTReceiver.buildERC20PermitApprovalMsg()`
     */
    function decodeArrayOfYieldBoxPermitAssetMsg(bytes memory _msg)
        internal
        pure
        returns (YieldBoxApproveAssetMsg[] memory)
    {
        /// @dev see `this.decodeERC20PermitApprovalMsg()`, token + owner + spender + value + deadline + v + r + s length = 189.
        uint256 msgCount_ = _msg.length / 190;

        YieldBoxApproveAssetMsg[] memory approvalMsgs_ = new YieldBoxApproveAssetMsg[](msgCount_);

        uint256 msgIndex_;
        for (uint256 i; i < msgCount_;) {
            approvalMsgs_[i] = decodeYieldBoxApprovalAssetMsg(BytesLib.slice(_msg, msgIndex_, 190));
            unchecked {
                msgIndex_ += 190;
                ++i;
            }
        }

        return approvalMsgs_;
    }

    /**
     * @notice Encodes the message for the `TOFTReceiver._yieldBoxRevokeAllReceiver()` operation.
     */
    function buildYieldBoxApproveAllMsg(YieldBoxApproveAllMsg memory _yieldBoxApprovalAllMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _yieldBoxApprovalAllMsg.target,
            _yieldBoxApprovalAllMsg.owner,
            _yieldBoxApprovalAllMsg.spender,
            _yieldBoxApprovalAllMsg.deadline,
            _yieldBoxApprovalAllMsg.v,
            _yieldBoxApprovalAllMsg.r,
            _yieldBoxApprovalAllMsg.s,
            _yieldBoxApprovalAllMsg.permit
        );
    }

    /**
     * @notice Encodes the message for the `TOFTReceiver._yieldBoxMarketPermitActionReceiver()` operation.
     */
    function buildMarketPermitApprovalMsg(MarketPermitActionMsg memory _marketApprovalMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _marketApprovalMsg.target,
            _marketApprovalMsg.owner,
            _marketApprovalMsg.spender,
            _marketApprovalMsg.value,
            _marketApprovalMsg.deadline,
            _marketApprovalMsg.v,
            _marketApprovalMsg.r,
            _marketApprovalMsg.s,
            _marketApprovalMsg.permitAsset
        );
    }

    struct __marketOffsets {
        uint8 targetOffset;
        uint8 ownerOffset;
        uint8 spenderOffset;
        uint8 valueOffset;
        uint8 deadlineOffset;
        uint8 vOffset;
        uint8 rOffset;
        uint8 sOffset;
    }

    /**
     * @notice Decodes an encoded message for the `TOFTReceiver.marketPermitActionReceiver()` operation.
     *
     *                    *   message packet   *
     * ------------------------------------------------------------- *
     * Name          | type      | start | end                       *
     * ------------------------------------------------------------- *
     * target        | address   | 0     | 20                        *
     * ------------------------------------------------------------- *
     * owner         | address   | 20    | 40                        *
     * ------------------------------------------------------------- *
     * spender       | address   | 40    | 60                        *
     * ------------------------------------------------------------- *
     * value         | address   | 60    | 92                        *
     * ------------------------------------------------------------- *
     * deadline      | uint256   | 92   | 124                        *
     * ------------------------------------------------------------- *
     * v             | uint8     | 124  | 125                        *
     * ------------------------------------------------------------- *
     * r             | bytes32   | 125  | 157                        *
     * ------------------------------------------------------------- *
     * s             | bytes32   | 157  | 189                        *
     * ------------------------------------------------------------- *
     * ------------------------------------------------------------- *
     * permitLend    | bool      | 189  | 190                        *
     * ------------------------------------------------------------- *
     *
     * @param _msg The encoded message. see `TOFTMsgCodec.buildMarketPermitApprovalMsg()`
     */
    function decodeMarketPermitApprovalMsg(bytes memory _msg)
        internal
        pure
        returns (MarketPermitActionMsg memory marketPermitActionMsg_)
    {
        __marketOffsets memory offsets_ = __marketOffsets({
            targetOffset: 20,
            ownerOffset: 40,
            spenderOffset: 60,
            valueOffset: 92,
            deadlineOffset: 124,
            vOffset: 125,
            rOffset: 157,
            sOffset: 189
        });

        // Decoded data
        address target = BytesLib.toAddress(BytesLib.slice(_msg, 0, offsets_.targetOffset), 0);

        address owner = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.targetOffset, 20), 0);

        address spender = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.ownerOffset, 20), 0);

        uint256 value = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.spenderOffset, 32), 0);

        uint256 deadline = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.valueOffset, 32), 0);

        uint8 v = uint8(BytesLib.toUint8(BytesLib.slice(_msg, offsets_.deadlineOffset, 1), 0));

        bytes32 r = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.vOffset, 32), 0);

        bytes32 s = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.rOffset, 32), 0);

        bool permitLend = _msg[offsets_.sOffset] != 0;

        // Return structured data
        marketPermitActionMsg_ = MarketPermitActionMsg(target, owner, spender, value, deadline, v, r, s, permitLend);
    }

    struct __ybOffsets {
        uint8 targetOffset;
        uint8 ownerOffset;
        uint8 spenderOffset;
        uint8 deadlineOffset;
        uint8 vOffset;
        uint8 rOffset;
        uint8 sOffset;
    }

    /**
     * @notice Decodes an encoded message for the `TOFTReceiver.ybPermitAll()` operation.
     *
     *                    *   message packet   *
     * ------------------------------------------------------------- *
     * Name          | type      | start | end                       *
     * ------------------------------------------------------------- *
     * target        | address   | 0     | 20                        *
     * ------------------------------------------------------------- *
     * owner         | address   | 20    | 40                        *
     * ------------------------------------------------------------- *
     * spender       | address   | 40    | 60                        *
     * ------------------------------------------------------------- *
     * deadline      | uint256   | 60   | 92                         *
     * ------------------------------------------------------------- *
     * v             | uint8     | 92   | 93                         *
     * ------------------------------------------------------------- *
     * r             | bytes32   | 93   | 125                        *
     * ------------------------------------------------------------- *
     * s             | bytes32   | 125   | 157                       *
     * ------------------------------------------------------------- *
     * permit        | bool      | 157   | 158                       *
     * ------------------------------------------------------------- *
     *
     * @param _msg The encoded message. see `TOFTMsgCodec.buildYieldBoxPermitAll()`
     */
    function decodeYieldBoxApproveAllMsg(bytes memory _msg)
        internal
        pure
        returns (YieldBoxApproveAllMsg memory ybPermitAllMsg_)
    {
        __ybOffsets memory offsets_ = __ybOffsets({
            targetOffset: 20,
            ownerOffset: 40,
            spenderOffset: 60,
            deadlineOffset: 92,
            vOffset: 93,
            rOffset: 125,
            sOffset: 157
        });

        // Decoded data
        address target = BytesLib.toAddress(BytesLib.slice(_msg, 0, offsets_.targetOffset), 0);
        address owner = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.targetOffset, 20), 0);
        address spender = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.ownerOffset, 20), 0);
        uint256 deadline = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.spenderOffset, 32), 0);
        uint8 v = uint8(BytesLib.toUint8(BytesLib.slice(_msg, offsets_.deadlineOffset, 1), 0));
        bytes32 r = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.vOffset, 32), 0);
        bytes32 s = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.rOffset, 32), 0);

        bool permit = _msg[offsets_.sOffset] != 0;

        // Return structured data
        ybPermitAllMsg_ = YieldBoxApproveAllMsg(target, owner, spender, deadline, v, r, s, permit);
    }

    // /**
    //  * @notice Decodes the next message of extra options, if any.
    //  */
    // function decodeNextMsgOfExtraOptions(bytes memory _options) internal view returns (bytes memory nextMsg_) {
    //     uint16 OP_BLDR_GAS_OFFSET = 8;
    //     uint16 OP_BLDR_VALUE_OFFSET = 24;

    //     uint16 optionLength_ = decodeLengthOfExtraOptions(_options);
    //     console.log("optionLength_", optionLength_);

    //     /// @dev Value can be omitted if it's 0.
    //     /// check LZ `OptionBuilder.addExecutorLzComposeOption()` and `ExecutorOptions.encodeLzComposeOption()`
    //     /// 19 = OptionType (1) + Index (8) + Gas (16)
    //     if (optionLength_ == 19) {
    //         uint16 nextMsgOffset = OP_BLDR_GAS_OFFSET + 16; // 8 + 16 = 24
    //         console.log(nextMsgOffset);
    //         if (_options.length > nextMsgOffset) {
    //             nextMsg_ = BytesLib.slice(_options, nextMsgOffset, _options.length - nextMsgOffset);
    //         }
    //     }
    //     /// 35 = OptionType (1) + Index (8) + Gas (16) + Value (16)
    //     if (optionLength_ == 35) {
    //         uint16 nextMsgOffset = OP_BLDR_VALUE_OFFSET + 16; // 24 + 16 = 40
    //         if (_options.length > nextMsgOffset) {
    //             nextMsg_ = BytesLib.slice(_options, nextMsgOffset, _options.length - nextMsgOffset);
    //         }
    //     }
    // }

    /**
     * @notice Decode an OFT `_lzReceive()` message.
     *
     *          *    LzCompose message packet    *
     * ------------------------------------------------------------- *
     * Name           | type      | start | end                      *
     * ------------------------------------------------------------- *
     * composeSender  | bytes32   | 0     | 32                       *
     * ------------------------------------------------------------- *
     * oftComposeMsg_ | bytes     | 32    | _msg.Length              *
     * ------------------------------------------------------------- *
     *
     * @param _msg The composed message for the send() operation.
     * @return composeSender_ The address of the compose sender. (dst OApp).
     * @return oftComposeMsg_ The TapOFT composed message, which is the actual message.
     */
    function decodeLzComposeMsg(bytes calldata _msg)
        internal
        pure
        returns (address composeSender_, bytes memory oftComposeMsg_)
    {
        composeSender_ = OFTMsgCodec.bytes32ToAddress(bytes32(BytesLib.slice(_msg, 0, LZ_COMPOSE_SENDER)));

        oftComposeMsg_ = BytesLib.slice(_msg, LZ_COMPOSE_SENDER, _msg.length - LZ_COMPOSE_SENDER);
    }

    /**
     *          *    LzCompose message packet    *
     * ------------------------------------------------------------- *
     * Name           | type      | start | end                      *
     * ------------------------------------------------------------- *
     * composeSender  | bytes32   | 0     | 32                       *
     * ------------------------------------------------------------- *
     * oftComposeMsg_ | bytes     | 32    | _msg.Length              *
     * ------------------------------------------------------------- *
     *
     *
     * @param _options  The option to decompose.
     */
    function decodeExecutorLzComposeOption(bytes memory _options) internal pure returns (address executor_) {
        return OFTMsgCodec.bytes32ToAddress(bytes32(BytesLib.slice(_options, 0, 32)));
    }

    /**
     * @notice Encodes the message for the `remoteTransfer` operation.
     * @param _remoteTransferMsg The owner + LZ send param to pass on the remote chain. (B->A)
     */
    function buildRemoteTransferMsg(RemoteTransferMsg memory _remoteTransferMsg) internal pure returns (bytes memory) {
        return abi.encode(_remoteTransferMsg);
    }

    /**
     * @notice Decode the message for the `remoteTransfer` operation.
     * @param _msg The owner + LZ send param to pass on the remote chain. (B->A)
     */
    function decodeRemoteTransferMsg(bytes memory _msg)
        internal
        pure
        returns (RemoteTransferMsg memory remoteTransferMsg_)
    {
        return abi.decode(_msg, (RemoteTransferMsg));
    }

    // ***************************************
    // * Encoding & Decoding TapOFT messages *
    // ***************************************

    /**
     * @notice Encodes the message for the `TapTokenReceiver._erc20PermitApprovalReceiver()` operation.
     */
    function encodeERC20PermitApprovalMsg(ERC20PermitApprovalMsg[] memory _erc20PermitApprovalMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(_erc20PermitApprovalMsg);
    }

    function decodeERC20PermitApprovalMsg(bytes memory _msg)
        internal
        pure
        returns (ERC20PermitApprovalMsg[] memory erc20PermitApprovalMsg_)
    {
        return abi.decode(_msg, (ERC20PermitApprovalMsg[]));
    }

    /**
     * @notice Encodes the message for the `TapTokenReceiver._erc721PermitApprovalReceiver()` operation.
     */
    function encodeERC721PermitApprovalMsg(ERC721PermitApprovalMsg[] memory _erc721PermitApprovalMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(_erc721PermitApprovalMsg);
    }

    /**
     * @notice Decodes an encoded message for the `TapTokenReceiver.erc721PermitApprovalReceiver()` operation.
     */
    function decodeERC721PermitApprovalMsg(bytes memory _msg)
        internal
        pure
        returns (ERC721PermitApprovalMsg[] memory)
    {
        return abi.decode(_msg, (ERC721PermitApprovalMsg[]));
    }

    function encodePearlmitApprovalMsg(
        address pearlmit,
        IPearlmit.PermitBatchTransferFrom memory _permitBatchTransferFrom
    ) internal pure returns (bytes memory) {
        return abi.encode(pearlmit, _permitBatchTransferFrom);
    }

    function decodePearlmitBatchApprovalMsg(bytes memory _msg)
        internal
        pure
        returns (address pearlmit, IPearlmit.PermitBatchTransferFrom memory _permitBatchTransferFrom)
    {
        return abi.decode(_msg, (address, IPearlmit.PermitBatchTransferFrom));
    }
}
