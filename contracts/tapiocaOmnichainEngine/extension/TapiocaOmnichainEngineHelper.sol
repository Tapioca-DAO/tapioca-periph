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

// Tapioca
import {
    ITapiocaOmnichainEngine,
    ERC20PermitApprovalMsg,
    ERC721PermitApprovalMsg,
    LZSendParam,
    ERC20PermitStruct,
    ERC721PermitStruct,
    ERC20PermitApprovalMsg,
    ERC721PermitApprovalMsg,
    RemoteTransferMsg
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {TapiocaOmnichainEngineCodec} from "../TapiocaOmnichainEngineCodec.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {BaseToeMsgType} from "../BaseToeMsgType.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @notice Used to build the TOE compose messages.
 */
struct ComposeMsgData {
    uint8 index; // The index of the message.
    uint128 gas; // The gasLimit used on the compose() function in the OApp for this message.
    uint128 value; // The msg.value passed to the compose() function in the OApp for this message.
    bytes data; // The data of the message.
    bytes prevData; // The previous compose msg data, if any. Used to aggregate the compose msg data.
    bytes prevOptionsData; // The previous compose msg options data, if any. Used to aggregate  the compose msg options.
}

/**
 * @notice Used to prepare an LZ call. See `TapiocaOmnichainHelper.prepareLzCall()`.
 */
struct PrepareLzCallData {
    uint32 dstEid; // The destination endpoint ID.
    bytes32 recipient; // The recipient address. Receiver of the OFT send if any.
    uint256 amountToSendLD; // The amount to send in the OFT send. If any.
    uint256 minAmountToCreditLD; // The min amount to credit in the OFT send. If any.
    uint16 msgType; // The message type, TOE custom ones, with `MSG_` as a prefix.
    ComposeMsgData composeMsgData; // The compose msg data.
    uint128 lzReceiveGas; // The gasLimit used on the lzReceive() function in the OApp.
    uint128 lzReceiveValue; // The msg.value passed to the lzReceive() function in the OApp.
}

/**
 * @notice Used to return the result of the `TapiocaOmnichainHelper.prepareLzCall()` function.
 */
struct PrepareLzCallReturn {
    bytes composeMsg; // The composed message. Can include previous composeMsg if any.
    bytes composeOptions; // The options of the composeMsg. Single option container, not aggregated with previous composeMsgOptions.
    SendParam sendParam; // OFT basic Tx params.
    MessagingFee msgFee; // OFT msg fee, include aggregation of previous composeMsgOptions.
    LZSendParam lzSendParam; // LZ Tx params. contains multiple information for the Tapioca `sendPacket()` call.
    bytes oftMsgOptions; // OFT msg options, include aggregation of previous composeMsgOptions.
}

/**
 * @title TapiocaOmnichainEngineHelper
 * @author TapiocaDAO
 * @notice Used as a helper contract to build calls to a TOE contract and view functions.
 */
contract TapiocaOmnichainEngineHelper is BaseToeMsgType {
    error InvalidMsgType(uint16 msgType); // Triggered if the msgType is invalid on an `_lzCompose`.
    error InvalidMsgIndex(uint16 msgIndex, uint16 expectedIndex); // The msgIndex does not follow the sequence of indexes in the `_toeComposeMsg`
    error InvalidExtraOptionsIndex(uint16 msgIndex, uint16 expectedIndex); // The option index does not follow the sequence of indexes in the `_toeComposeMsg`

    /**
     * ==========================
     * ERC20 APPROVAL MSG BUILDER
     * ==========================
     */

    /**
     * @dev Helper to prepare an LZ call.
     * @dev Refunds address is the caller. // TODO add refundAddress field.
     * @dev `amountToSendLD` and `minAmountToCreditLD` are used for an OFT send operation. If set in composed calls, only the last message LZ data will be used.
     * @dev !!! IMPORTANT !!! If you want to send a message without sending amounts, set both `amountToSendLD` and `minAmountToCreditLD` to 0.
     *
     * @return prepareLzCallReturn_ The result of the `prepareLzCall()` function. See `PrepareLzCallReturn`.
     */
    function prepareLzCall(ITapiocaOmnichainEngine _toeToken, PrepareLzCallData memory _prepareLzCallData)
        public
        view
        returns (PrepareLzCallReturn memory prepareLzCallReturn_)
    {
        SendParam memory sendParam_;
        bytes memory composeOptions_;
        bytes memory composeMsg_;
        MessagingFee memory msgFee_;
        LZSendParam memory lzSendParam_;
        bytes memory oftMsgOptions_;

        // Prepare args call
        sendParam_ = SendParam({
            dstEid: _prepareLzCallData.dstEid,
            to: _prepareLzCallData.recipient,
            amountLD: _prepareLzCallData.amountToSendLD,
            minAmountLD: _prepareLzCallData.minAmountToCreditLD,
            extraOptions: "0x",
            composeMsg: "0x",
            oftCmd: "0x"
        });

        // If compose call found, we get its compose options and message.
        if (_prepareLzCallData.composeMsgData.data.length > 0) {
            composeOptions_ = OptionsBuilder.addExecutorLzComposeOption(
                OptionsBuilder.newOptions(),
                _prepareLzCallData.composeMsgData.index,
                _prepareLzCallData.composeMsgData.gas,
                _prepareLzCallData.composeMsgData.value
            );

            // Build the composed message. Overwrite `composeOptions_` to be with the enforced options.
            (composeMsg_, composeOptions_) = buildToeComposeMsgAndOptions(
                _toeToken,
                _prepareLzCallData.composeMsgData.data,
                _prepareLzCallData.msgType,
                _prepareLzCallData.composeMsgData.index,
                sendParam_.dstEid,
                composeOptions_,
                _prepareLzCallData.composeMsgData.prevData // Previous tapComposeMsg.
            );
        }

        // Append previous option container if any.
        if (_prepareLzCallData.composeMsgData.prevOptionsData.length > 0) {
            require(
                _prepareLzCallData.composeMsgData.prevOptionsData.length > 0, "_prepareLzCall: invalid prevOptionsData"
            );
            oftMsgOptions_ = _prepareLzCallData.composeMsgData.prevOptionsData;
        } else {
            // Else create a new one.
            oftMsgOptions_ = OptionsBuilder.newOptions();
        }

        // Start by appending the lzReceiveOption if lzReceiveGas or lzReceiveValue is > 0.
        if (_prepareLzCallData.lzReceiveValue > 0 || _prepareLzCallData.lzReceiveGas > 0) {
            oftMsgOptions_ = OptionsBuilder.addExecutorLzReceiveOption(
                oftMsgOptions_, _prepareLzCallData.lzReceiveGas, _prepareLzCallData.lzReceiveValue
            );
        }

        // Finally, append the new compose options if any.
        if (composeOptions_.length > 0) {
            // And append the same value passed to the `composeOptions`.
            oftMsgOptions_ = OptionsBuilder.addExecutorLzComposeOption(
                oftMsgOptions_,
                _prepareLzCallData.composeMsgData.index,
                _prepareLzCallData.composeMsgData.gas,
                _prepareLzCallData.composeMsgData.value
            );
        }

        msgFee_ = _toeToken.quoteSendPacket(sendParam_, oftMsgOptions_, false, composeMsg_, "");

        sendParam_.extraOptions = oftMsgOptions_;
        sendParam_.composeMsg = composeMsg_;

        lzSendParam_ = LZSendParam({
            sendParam: sendParam_,
            fee: msgFee_,
            extraOptions: oftMsgOptions_,
            refundAddress: address(msg.sender)
        });

        prepareLzCallReturn_ = PrepareLzCallReturn({
            composeMsg: composeMsg_,
            composeOptions: composeOptions_,
            sendParam: sendParam_,
            msgFee: msgFee_,
            lzSendParam: lzSendParam_,
            oftMsgOptions: oftMsgOptions_
        });
    }

    /// =======================
    /// Builder functions
    /// =======================

    /**
     * @notice Encode the message for the _erc20PermitApprovalReceiver() operation.
     * @param _erc20PermitApprovalMsg The ERC20 permit approval messages.
     */
    function encodeERC20PermitApprovalMsg(ERC20PermitApprovalMsg[] memory _erc20PermitApprovalMsg)
        public
        pure
        returns (bytes memory msg_)
    {
        return TapiocaOmnichainEngineCodec.encodeERC20PermitApprovalMsg(_erc20PermitApprovalMsg);
    }

    /**
     * @notice Encode the message for the _erc721PermitApprovalReceiver() operation.
     * @param _erc721PermitApprovalMsg The ERC721 permit approval messages.
     */
    function encodeERC721PermitApprovalMsg(ERC721PermitApprovalMsg[] memory _erc721PermitApprovalMsg)
        public
        pure
        returns (bytes memory msg_)
    {
        return TapiocaOmnichainEngineCodec.encodeERC721PermitApprovalMsg(_erc721PermitApprovalMsg);
    }

    function encodePearlmitApprovalMsg(address _pearlmit, IPearlmit.PermitBatchTransferFrom calldata _data)
        public
        pure
        returns (bytes memory msg_)
    {
        return TapiocaOmnichainEngineCodec.encodePearlmitApprovalMsg(_pearlmit, _data);
    }

    /**
     * @notice Encodes the message for the `remoteTransfer` operation.
     * @param _remoteTransferMsg The owner + LZ send param to pass on the remote chain. (B->A)
     */
    function buildRemoteTransferMsg(RemoteTransferMsg memory _remoteTransferMsg) public pure returns (bytes memory) {
        return TapiocaOmnichainEngineCodec.buildRemoteTransferMsg(_remoteTransferMsg);
    }

    /// =======================
    /// Compose builder functions
    /// =======================

    /**
     * @dev Internal function to build the message and options.
     *
     * @param _msg The TAP message to be encoded.
     * @param _msgType The message type, TAP custom ones, with `MSG_` as a prefix.
     * @param _msgIndex The index of the current TAP compose msg.
     * @param _dstEid The destination endpoint ID.
     * @param _extraOptions Extra options for this message. Used to add extra options or aggregate previous `_tapComposedMsg` options.
     * @param _tapComposedMsg The previous TAP compose messages. Empty if this is the first message.
     *
     * @return message The encoded message.
     * @return options The encoded options.
     */
    function buildToeComposeMsgAndOptions(
        ITapiocaOmnichainEngine _toeToken,
        bytes memory _msg,
        uint16 _msgType,
        uint16 _msgIndex,
        uint32 _dstEid,
        bytes memory _extraOptions,
        bytes memory _tapComposedMsg
    ) public view returns (bytes memory message, bytes memory options) {
        _sanitizeMsgType(_msgType);
        _sanitizeMsgIndex(_msgIndex, _tapComposedMsg);

        message = TapiocaOmnichainEngineCodec.encodeToeComposeMsg(_msg, _msgType, _msgIndex, _tapComposedMsg);

        // TODO fix
        // _sanitizeExtraOptionsIndex(_msgIndex, _extraOptions);
        // @dev Combine the callers _extraOptions with the enforced options via the OAppOptionsType3.

        options = _toeToken.combineOptions(_dstEid, _msgType, _extraOptions);
    }

    // TODO remove sanitization? If `_sendPacket()` is internal, then the msgType is what we expect it to be.
    /**
     * @dev Sanitizes the message type to match one of the Tapioca supported ones.
     * @param _msgType The message type, custom ones with `MSG_` as a prefix.
     */
    function _sanitizeMsgType(uint16 _msgType) internal pure {
        if (
            // LZ
            _msgType == MSG_SEND
            // Tapioca msg types
            || _msgType == MSG_APPROVALS || _msgType == MSG_NFT_APPROVALS || _msgType == MSG_PEARLMIT_APPROVAL
                || _msgType == MSG_REMOTE_TRANSFER
        ) {
            return;
        } else if (!_sanitizeMsgTypeExtended(_msgType)) {
            revert InvalidMsgType(_msgType);
        }
    }

    /**
     * @dev Sanitizes the message type of a TOE inherited contract.
     */
    function _sanitizeMsgTypeExtended(uint16 _msgType) internal pure virtual returns (bool) {}

    /**
     * @dev Sanitizes the msgIndex to match the sequence of indexes in the `_toeComposeMsg`.
     *
     * @param _msgIndex The current message index.
     * @param _toeComposeMsg The previous TAP compose messages. Empty if this is the first message.
     */
    function _sanitizeMsgIndex(uint16 _msgIndex, bytes memory _toeComposeMsg) internal pure {
        // If the msgIndex is 0 and there's no composeMsg, then it's the first message.
        if (_toeComposeMsg.length == 0 && _msgIndex == 0) {
            return;
        }

        bytes memory nextMsg_ = _toeComposeMsg;
        uint16 lastIndex_;
        while (nextMsg_.length > 0) {
            lastIndex_ = TapiocaOmnichainEngineCodec.decodeIndexOfToeComposeMsg(nextMsg_);
            nextMsg_ = TapiocaOmnichainEngineCodec.decodeNextMsgOfToeCompose(nextMsg_);
        }

        // If there's a composeMsg, then the msgIndex must be greater than 0, and an increment of the last msgIndex.
        uint16 expectedMsgIndex_ = lastIndex_ + 1;
        if (_toeComposeMsg.length > 0) {
            if (_msgIndex == expectedMsgIndex_) {
                return;
            }
        }

        revert InvalidMsgIndex(_msgIndex, expectedMsgIndex_);
    }

    /// =======================
    /// View helpers
    /// =======================
    /**
     * @dev Convert an amount from shared decimals into local decimals.
     * @param _amountSD The amount in shared decimals.
     * @param _decimalConversionRate The OFT decimal conversion rate
     * @return amountLD The amount in local decimals.
     */
    function toLD(uint64 _amountSD, uint256 _decimalConversionRate) external pure returns (uint256 amountLD) {
        return _amountSD * _decimalConversionRate;
    }

    /**
     * @dev Convert an amount from local decimals into shared decimals.
     * @param _amountLD The amount in local decimals.
     * @param _decimalConversionRate The OFT decimal conversion rate
     * @return amountSD The amount in shared decimals.
     */
    function toSD(uint256 _amountLD, uint256 _decimalConversionRate) external pure returns (uint64 amountSD) {
        return uint64(_amountLD / _decimalConversionRate);
    }
}
