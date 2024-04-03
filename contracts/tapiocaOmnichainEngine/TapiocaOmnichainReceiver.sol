// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {
    MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {IOAppMsgInspector} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppMsgInspector.sol";
import {IOAppComposer} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppComposer.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

// Tapioca
import {
    ITapiocaOmnichainReceiveExtender,
    ERC721PermitApprovalMsg,
    ERC20PermitApprovalMsg,
    RemoteTransferMsg,
    LZSendParam
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {TapiocaOmnichainEngineCodec} from "./TapiocaOmnichainEngineCodec.sol";
import {BaseTapiocaOmnichainEngine} from "./BaseTapiocaOmnichainEngine.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract TapiocaOmnichainReceiver is BaseTapiocaOmnichainEngine, IOAppComposer {
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

    /**
     *  @dev Triggered if the address of the composer doesn't match current contract in `lzCompose`.
     * Compose caller and receiver are the same address, which is this.
     */
    error InvalidComposer(address composer);
    error InvalidCaller(address caller); // Should be the endpoint address
    error InvalidMsgType(uint16 msgType); // Triggered if the msgType is invalid on an `_lzCompose`.

    /// @dev Compose received.
    event ComposeReceived(uint16 indexed msgType, bytes32 indexed guid, bytes composeMsg);
    /// @dev twTAP unlock operation received.
    event RemoteTransferReceived(address indexed owner, uint256 indexed dstEid, address indexed to, uint256 amount);

    /**
     * @dev !!! FIRST ENTRYPOINT, COMPOSE MSG ARE TO BE BUILT HERE  !!!
     *
     * @dev Slightly modified version of the OFT _lzReceive() operation.
     * The composed message is sent to `address(this)` instead of `toAddress`.
     * @dev Internal function to handle the receive on the LayerZero endpoint.
     * @dev Caller is verified on the public function. See `OAppReceiver.lzReceive()`.
     *
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The encoded message.
     * _executor The address of the executor.
     * _extraData Additional data.
     */
    // TODO check if OApp sender is sanitized?
    // TODO !!!!!!!!! Perform ld2sd conversion on the compose messages amounts.
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address, /*_executor*/ // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        // @dev The src sending chain doesn't know the address length on this chain (potentially non-evm)
        // Thus everything is bytes32() encoded in flight.
        address toAddress = _message.sendTo().bytes32ToAddress();
        // @dev Convert the amount to credit into local decimals.
        uint256 amountToCreditLD = _toLD(_message.amountSD());
        // @dev Credit the amount to the recipient and return the ACTUAL amount the recipient received in local decimals
        uint256 amountReceivedLD = _credit(toAddress, amountToCreditLD, _origin.srcEid);

        if (_message.isComposed()) {
            // @dev Stores the lzCompose payload that will be executed in a separate tx.
            // Standardizes functionality for executing arbitrary contract invocation on some non-evm chains.
            // @dev The off-chain executor will listen and process the msg based on the src-chain-callers compose options passed.
            // @dev The index is used when a OApp needs to compose multiple msgs on lzReceive.
            // For default OFT implementation there is only 1 compose msg per lzReceive, thus its always 0.
            endpoint.sendCompose(
                address(this), // Updated from default `toAddress`
                _guid,
                0, /* the index of the composed message*/
                _message.composeMsg()
            );
        }

        emit OFTReceived(_guid, _origin.srcEid, toAddress, amountReceivedLD);
    }

    // TODO - SANITIZE MSG TYPE
    /**
     * @dev !!! SECOND ENTRYPOINT, CALLER NEEDS TO BE VERIFIED !!!
     *
     * @notice Composes a LayerZero message from an OApp.
     * @dev The message comes in form:
     *      - [composeSender::address][oftComposeMsg::bytes]
     *                                          |
     *                                          |
     *                        [msgType::uint16, composeMsg::bytes]
     * @dev The composeSender is the user that initiated the `sendPacket()` call on the srcChain.
     *
     * @param _from The address initiating the composition, typically the OApp where the lzReceive was called.
     * @param _guid The unique identifier for the corresponding LayerZero src/dst tx.
     * @param _message The composed message payload in bytes. NOT necessarily the same payload passed via lzReceive.
     */
    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address, //executor
        bytes calldata //extra Data
    ) external payable override {
        // Validate the from and the caller.
        if (_from != address(this)) {
            revert InvalidComposer(_from);
        }
        if (msg.sender != address(endpoint)) {
            revert InvalidCaller(msg.sender);
        }

        // Decode LZ compose message.
        (address srcChainSender_, bytes memory oftComposeMsg_) =
            TapiocaOmnichainEngineCodec.decodeLzComposeMsg(_message);
        // Execute the composed message.
        _lzCompose(srcChainSender_, _guid, oftComposeMsg_);
    }

    /**
     * @dev Modifier behavior of composed calls to be executed as a single Tx.
     * Since composed msgs and approval
     */
    function _lzCompose(address srcChainSender_, bytes32 _guid, bytes memory oftComposeMsg_) internal {
        // Decode OFT compose message.
        (uint16 msgType_,,, bytes memory tapComposeMsg_, bytes memory nextMsg_) =
            TapiocaOmnichainEngineCodec.decodeToeComposeMsg(oftComposeMsg_);

        // Call Permits/approvals if the msg type is a permit/approval.
        // If the msg type is not a permit/approval, it will call the other receivers.
        if (msgType_ == MSG_REMOTE_TRANSFER) {
            _remoteTransferReceiver(srcChainSender_, tapComposeMsg_);
        } else if (!_extExec(msgType_, tapComposeMsg_)) {
            // Check if the TOE extender is set and the msg type is valid. If so, call the TOE extender to handle msg.
            if (
                address(tapiocaOmnichainReceiveExtender) != address(0)
                    && tapiocaOmnichainReceiveExtender.isMsgTypeValid(msgType_)
            ) {
                bytes memory callData = abi.encodeWithSelector(
                    ITapiocaOmnichainReceiveExtender.toeComposeReceiver.selector,
                    msgType_,
                    srcChainSender_,
                    tapComposeMsg_
                );
                (bool success, bytes memory returnData) =
                    address(tapiocaOmnichainReceiveExtender).delegatecall(callData);
                if (!success) {
                    revert(_getTOEExtenderRevertMsg(returnData));
                }
            } else {
                // If no TOE extender is set or msg type doesn't match extender, try to call the internal receiver.
                if (!_toeComposeReceiver(msgType_, srcChainSender_, tapComposeMsg_)) {
                    revert InvalidMsgType(msgType_);
                }
            }
        }

        emit ComposeReceived(msgType_, _guid, tapComposeMsg_);
        if (nextMsg_.length > 0) {
            _lzCompose(srcChainSender_, _guid, nextMsg_);
        }
    }

    // ********************* //
    // ***** RECEIVERS ***** //
    // ********************* //

    /**
     * @dev Meant to be override by TOE contracts, such as tOFT or TapToken, to handle their own msg types.
     *
     * @param _msgType is the msgType of the composed message. See `TapiocaOmnichainEngineCodec.decodeToeComposeMsg()`.
     * See `BaseTapiocaOmnichainEngine` to see the default TOE messages types.
     * @param _srcChainSender The address of the sender on the source chain.
     * @param _toeComposeMsg is the composed message payload, of whatever the _msgType handler is expecting.
     * @return success is the success of the composed message handler. If no handler is found, it should return false to trigger `InvalidMsgType()`.
     */
    function _toeComposeReceiver(uint16 _msgType, address _srcChainSender, bytes memory _toeComposeMsg)
        internal
        virtual
        returns (bool success)
    {}

    /**
     * // TODO Check if it's safe to send composed messages too.
     * // TODO Write test for composed messages call. A->B->A-B/C?
     * @dev Transfers tokens AND composed messages from this contract to the recipient on the chain A. Flow of calls is: A->B->A.
     * @dev The user needs to have approved the TapToken contract to spend the TAP.
     *
     * @param _srcChainSender The address of the sender on the source chain.
     * @param _data The call data containing info about the transfer (LZSendParam).
     */
    function _remoteTransferReceiver(address _srcChainSender, bytes memory _data) internal virtual {
        RemoteTransferMsg memory remoteTransferMsg_ = TapiocaOmnichainEngineCodec.decodeRemoteTransferMsg(_data);

        /// @dev xChain owner needs to have approved dst srcChain `sendPacket()` msg.sender in a previous composedMsg. Or be the same address.
        _internalTransferWithAllowance(
            remoteTransferMsg_.owner, _srcChainSender, remoteTransferMsg_.lzSendParam.sendParam.amountLD
        );

        // Make the internal transfer, burn the tokens from this contract and send them to the recipient on the other chain.
        _internalRemoteTransferSendPacket(
            _srcChainSender, remoteTransferMsg_.lzSendParam, remoteTransferMsg_.composeMsg
        );

        emit RemoteTransferReceived(
            remoteTransferMsg_.owner,
            remoteTransferMsg_.lzSendParam.sendParam.dstEid,
            OFTMsgCodec.bytes32ToAddress(remoteTransferMsg_.lzSendParam.sendParam.to),
            remoteTransferMsg_.lzSendParam.sendParam.amountLD
        );
    }

    /**
     * // TODO review this function.
     *
     * @dev Slightly modified version of the OFT _sendPacket() operation. To accommodate the `srcChainSender` parameter and potential dust.
     * @dev !!! IMPORTANT !!! made ONLY for the `_remoteTransferReceiver()` operation.
     */
    function _internalRemoteTransferSendPacket(
        address _srcChainSender,
        LZSendParam memory _lzSendParam,
        bytes memory _composeMsg
    ) internal returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        // Burn tokens from this contract
        (uint256 amountDebitedLD_, uint256 amountToCreditLD_) = _debitView(
            _lzSendParam.sendParam.amountLD, _lzSendParam.sendParam.minAmountLD, _lzSendParam.sendParam.dstEid
        );
        _burn(address(this), amountToCreditLD_);

        _lzSendParam.sendParam.amountLD = amountToCreditLD_;
        _lzSendParam.sendParam.minAmountLD = amountToCreditLD_;

        // If the srcChain amount request is bigger than the debited one, overwrite the amount to credit with the amount debited and send the difference back to the user.
        if (_lzSendParam.sendParam.amountLD > amountDebitedLD_) {
            // Overwrite the amount to credit with the amount debited
            _lzSendParam.sendParam.amountLD = amountDebitedLD_;
            _lzSendParam.sendParam.minAmountLD = amountDebitedLD_;
            // Send the difference back to the user
            _transfer(address(this), _srcChainSender, _lzSendParam.sendParam.amountLD - amountDebitedLD_);
        }

        // Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildOFTMsgAndOptionsMemory(
            _lzSendParam.sendParam, _lzSendParam.extraOptions, _composeMsg, amountToCreditLD_, _srcChainSender
        ); // msgSender is the sender of the composed message. We keep context by passing `_srcChainSender`.

        // Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt =
            _lzSend(_lzSendParam.sendParam.dstEid, message, options, _lzSendParam.fee, _lzSendParam.refundAddress);
        // Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountDebitedLD_, amountToCreditLD_);

        emit OFTSent(msgReceipt.guid, _lzSendParam.sendParam.dstEid, _srcChainSender, amountDebitedLD_, amountToCreditLD_);
    }

    /**
     * @dev Performs a transfer with an allowance check and consumption against the xChain msg sender.
     * @dev Can only transfer to this address.
     *
     * @param _owner The account to transfer from.
     * @param srcChainSender The address of the sender on the source chain.
     * @param _amount The amount to transfer
     */
    function _internalTransferWithAllowance(address _owner, address srcChainSender, uint256 _amount) internal {
        if (_owner != srcChainSender) {
            _spendAllowance(_owner, srcChainSender, _amount);
        }

        _transfer(_owner, address(this), _amount);
    }

    /**
     * @notice Sends a permit/approval call to the `tapiocaOmnichainReceiveExtender` contract.
     * @param _msgType The type of the message.
     * @param _data The call data containing info about the message.
     * @return success is the success of the composed message handler. If no handler is found, it should return false to trigger `InvalidMsgType()`.
     */
    function _extExec(uint16 _msgType, bytes memory _data) internal returns (bool) {
        if (_msgType == MSG_APPROVALS) {
            toeExtExec.erc20PermitApproval(_data);
        } else if (_msgType == MSG_NFT_APPROVALS) {
            toeExtExec.erc721PermitApproval(_data);
        } else if (_msgType == MSG_PEARLMIT_APPROVAL) {
            toeExtExec.pearlmitApproval(_data);
        } else if (_msgType == MSG_YB_APPROVE_ALL) {
            toeExtExec.yieldBoxPermitAll(_data);
        } else if (_msgType == MSG_YB_APPROVE_ASSET) {
            toeExtExec.yieldBoxPermitAsset(_data);
        } else if (_msgType == MSG_MARKET_PERMIT) {
            toeExtExec.marketPermit(_data);
        } else {
            return false;
        }
        return true;
    }

    // ***************** //
    // ***** UTILS ***** //
    // ***************** //

    /**
     * @dev For details about this function, check `BaseTapiocaOmnichainEngine._buildOFTMsgAndOptions()`.
     * @dev !!!! IMPORTANT !!!! The differences are:
     *      - memory instead of calldata for parameters.
     *      - `_msgSender` is used instead of using context `msg.sender`, to preserve context of the OFT call and use `msg.sender` of the source chain.
     *      - Does NOT combine options, make sure to pass valid options to cover gas costs/value transfers.
     */
    function _buildOFTMsgAndOptionsMemory(
        SendParam memory _sendParam,
        bytes memory _extraOptions,
        bytes memory _composeMsg,
        uint256 _amountToCreditLD,
        address _msgSender
    ) internal view returns (bytes memory message, bytes memory options) {
        bool hasCompose = _composeMsg.length > 0;

        message = hasCompose
            ? abi.encodePacked(
                _sendParam.to, _toSD(_amountToCreditLD), OFTMsgCodec.addressToBytes32(_msgSender), _composeMsg
            )
            : abi.encodePacked(_sendParam.to, _toSD(_amountToCreditLD));
        options = _extraOptions;

        if (msgInspector != address(0)) {
            IOAppMsgInspector(msgInspector).inspect(message, options);
        }
    }

    /**
     * @notice Return the revert message from an external call.
     * @param _returnData The return data from the external call.
     */
    function _getTOEExtenderRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length > 1000) return "Module: reason too long";

        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Module: data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}
