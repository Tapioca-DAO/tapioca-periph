// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {IOAppMsgInspector} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppMsgInspector.sol";
import {SendParam, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

// Tapioca
import {TapiocaOmnichainExtExec} from "./extension/TapiocaOmnichainExtExec.sol";
import {BaseToeMsgType} from "./BaseToeMsgType.sol";

/*
__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

abstract contract BaseTapiocaOmnichainEngine is OFT, BaseToeMsgType {
    using BytesLib for bytes;
    using SafeERC20 for IERC20;
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

    uint16 internal constant PT_APPROVALS = 500; // Use for ERC20Permit approvals
    uint16 internal constant PT_NFT_APPROVALS = 501; // Use for ERC721Permit approvals
    uint16 internal constant PT_REMOTE_TRANSFER = 700; // Use for transferring tokens from the contract from another chain

    /// @dev Used to execute certain extern calls from the TapToken contract, such as ERC20Permit approvals.
    TapiocaOmnichainExtExec public toeExtExec;

    constructor(string memory _name, string memory _symbol, address _endpoint, address _owner)
        OFT(_name, _symbol, _endpoint, _owner)
    {
        toeExtExec = new TapiocaOmnichainExtExec();
    }

    /**
     * @dev public function to remove dust from the given local decimal amount.
     * @param _amountLD The amount in local decimals.
     * @return amountLD The amount after removing dust.
     *
     * @dev Prevents the loss of dust when moving amounts between chains with different decimals.
     * @dev eg. uint(123) with a conversion rate of 100 becomes uint(100).
     */
    function removeDust(uint256 _amountLD) public view virtual returns (uint256 amountLD) {
        return _removeDust(_amountLD);
    }

    /**
     * @dev Slightly modified version of the OFT quoteSend() operation. Includes a `_msgType` parameter.
     * The `_buildMsgAndOptionsByType()` appends the packet type to the message.
     * @notice Provides a quote for the send() operation.
     * @param _sendParam The parameters for the send() operation.
     * @param _extraOptions Additional options supplied by the caller to be used in the LayerZero message.
     * @param _payInLzToken Flag indicating whether the caller is paying in the LZ token.
     * @param _composeMsg The composed message for the send() operation.
     * @dev _oftCmd The OFT command to be executed.
     * @return msgFee The calculated LayerZero messaging fee from the send() operation.
     *
     * @dev MessagingFee: LayerZero msg fee
     *  - nativeFee: The native fee.
     *  - lzTokenFee: The lzToken fee.
     */
    function quoteSendPacket(
        SendParam calldata _sendParam,
        bytes calldata _extraOptions,
        bool _payInLzToken,
        bytes calldata _composeMsg,
        bytes calldata /*_oftCmd*/ // @dev unused in the default implementation.
    ) external view virtual returns (MessagingFee memory msgFee) {
        // @dev mock the amount to credit, this is the same operation used in the send().
        // The quote is as similar as possible to the actual send() operation.
        (, uint256 amountToCreditLD) =
            _debitView(_sendParam.amountToSendLD, _sendParam.minAmountToCreditLD, _sendParam.dstEid);

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) =
            _buildOFTMsgAndOptions(_sendParam, _extraOptions, _composeMsg, amountToCreditLD);

        // @dev Calculates the LayerZero fee for the send() operation.
        return _quote(_sendParam.dstEid, message, options, _payInLzToken);
    }

    /**
     * @notice Build an OFT message and option. The message contain OFT related info such as the amount to credit and the recipient.
     * It also contains the `_composeMsg`, which is 1 or more TAP specific messages. See `_buildTapMsgAndOptions()`.
     * The option is an aggregation of the OFT message as well as the TAP messages.
     *
     * @param _sendParam: The parameters for the send operation.
     *      - dstEid::uint32: Destination endpoint ID.
     *      - to::bytes32: Recipient address.
     *      - amountToSendLD::uint256: Amount to send in local decimals.
     *      - minAmountToCreditLD::uint256: Minimum amount to credit in local decimals.
     * @param _extraOptions Additional options for the send() operation. If `_composeMsg` not empty, the `_extraOptions` should also contain the aggregation of its options.
     * @param _composeMsg The composed message for the send() operation. Is a combination of 1 or more TAP specific messages.
     * @param _amountToCreditLD The amount to credit in local decimals.
     *
     * @return message The encoded message.
     * @return options The combined LZ msgType + `_extraOptions` options.
     */
    function _buildOFTMsgAndOptions(
        SendParam calldata _sendParam,
        bytes calldata _extraOptions,
        bytes calldata _composeMsg,
        uint256 _amountToCreditLD
    ) internal view returns (bytes memory message, bytes memory options) {
        bool hasCompose;

        // @dev This generated message has the msg.sender encoded into the payload so the remote knows who the caller is.
        // @dev NOTE the returned message will append `msg.sender` only if the message is composed.
        // If it's the case, it'll add the `address(msg.sender)` at the `amountToCredit` offset.
        (message, hasCompose) = OFTMsgCodec.encode(
            _sendParam.to,
            _toSD(_amountToCreditLD),
            // @dev Must be include a non empty bytes if you want to compose, EVEN if you don't need it on the remote.
            // EVEN if you don't require an arbitrary payload to be sent... eg. '0x01'
            _composeMsg
        );
        // @dev Change the msg type depending if its composed or not.
        uint16 _msgType = hasCompose ? SEND_AND_CALL : SEND;
        // @dev Combine the callers _extraOptions with the enforced options via the OAppOptionsType3.
        options = combineOptions(_sendParam.dstEid, _msgType, _extraOptions);

        // @dev Optionally inspect the message and options depending if the OApp owner has set a msg inspector.
        // @dev If it fails inspection, needs to revert in the implementation. ie. does not rely on return boolean
        if (msgInspector != address(0)) {
            IOAppMsgInspector(msgInspector).inspect(message, options);
        }
    }

    /**
     * @dev Internal function to return the current EID.
     */
    function _getChainId() internal view virtual returns (uint32) {}
}
