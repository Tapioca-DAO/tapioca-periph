// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {IOAppMsgInspector} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppMsgInspector.sol";
import {SendParam, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {OAppSender} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

// Tapioca
import {ITapiocaOmnichainReceiveExtender} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {PearlmitHandler, IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {TapiocaOmnichainExtExec} from "./extension/TapiocaOmnichainExtExec.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {BaseToeMsgType} from "./BaseToeMsgType.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract BaseTapiocaOmnichainEngine is OFT, PearlmitHandler, BaseToeMsgType {
    using BytesLib for bytes;
    using SafeERC20 for IERC20;
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

    /// @dev Used to execute certain extern calls from the TapToken contract, such as ERC20Permit approvals.
    TapiocaOmnichainExtExec public toeExtExec;
    /// @dev For future use, to extend the receive() operation.
    ITapiocaOmnichainReceiveExtender public tapiocaOmnichainReceiveExtender;

    error BaseTapiocaOmnichainEngine_PearlmitNotApproved();
    error BaseTapiocaOmnichainEngine_PearlmitFailed();
    error BaseTapiocaOmnichainEngine__ZeroAddress();

    // keccak256("BaseToe.cluster.slot")
    bytes32 public constant CLUSTER_SLOT = 0x7cdf5007585d1c7d3dfb23c59fcda5f9f02da78637d692495255a57630b72162;

    constructor(
        string memory _name,
        string memory _symbol,
        address _endpoint,
        address _delegate,
        address _extExec,
        IPearlmit _pearlmit,
        ICluster _cluster
    ) OFT(_name, _symbol, _endpoint, _delegate) PearlmitHandler(_pearlmit) {
        toeExtExec = TapiocaOmnichainExtExec(_extExec);

        StorageSlot.getAddressSlot(CLUSTER_SLOT).value = address(_cluster);
    }

    /**
     * @inheritdoc OAppSender
     * @dev Overwrite to check for < values.
     */
    function _payNative(uint256 _nativeFee) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return msg.value;
    }

    /**
     * @dev Sets the `tapiocaOmnichainReceiveExtender` contract.
     */
    function setTapiocaOmnichainReceiveExtender(address _tapiocaOmnichainReceiveExtender) external onlyOwner {
        tapiocaOmnichainReceiveExtender = ITapiocaOmnichainReceiveExtender(_tapiocaOmnichainReceiveExtender);
    }

    /**
     * @dev Sets the `toeExtExec` contract.
     */
    function setToeExtExec(address _extExec) external onlyOwner {
        toeExtExec = TapiocaOmnichainExtExec(_extExec);
    }

    /**
     * @dev Returns the current cluster.
     */
    function getCluster() public view returns (ICluster) {
        return ICluster(StorageSlot.getAddressSlot(CLUSTER_SLOT).value);
    }

    /**
     * @dev Sets the cluster.
     */
    function setCluster(ICluster _cluster) external onlyOwner {
        StorageSlot.getAddressSlot(CLUSTER_SLOT).value = address(_cluster);
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
        (, uint256 amountToCreditLD) = _debitView(_sendParam.amountLD, _sendParam.minAmountLD, _sendParam.dstEid);

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) =
            _buildOFTMsgAndOptions(address(0), _sendParam, _extraOptions, _composeMsg, amountToCreditLD);

        // @dev Calculates the LayerZero fee for the send() operation.
        return _quote(_sendParam.dstEid, message, options, _payInLzToken);
    }

    /**
     * @notice Build an OFT message and option. The message contain OFT related info such as the amount to credit and the recipient.
     * It also contains the `_composeMsg`, which is 1 or more TAP specific messages. See `_buildTapMsgAndOptions()`.
     * The option is an aggregation of the OFT message as well as the TAP messages.
     *
     * @param _from The sender address. If address(0), msg.sender is used.
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
        address _from,
        SendParam calldata _sendParam,
        bytes calldata _extraOptions,
        bytes calldata _composeMsg,
        uint256 _amountToCreditLD
    ) internal view returns (bytes memory message, bytes memory options) {
        bool hasCompose;

        // @dev This generated message has the msg.sender encoded into the payload so the remote knows who the caller is.
        // @dev NOTE the returned message will append `msg.sender` only if the message is composed.
        // If it's the case, it'll add the `address(msg.sender)` at the `amountToCredit` offset.
        (message, hasCompose) = encode(
            _from,
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
     * @dev copy paste of OFTMsgCodec::encode(). Difference is `_from` is passed as a parameter.
     * and update the source chain sender.
     */
    function encode(address _from, bytes32 _sendTo, uint64 _amountShared, bytes memory _composeMsg)
        internal
        pure
        returns (bytes memory _msg, bool hasCompose)
    {
        hasCompose = _composeMsg.length > 0;
        // @dev Remote chains will want to know the composed function caller ie. msg.sender on the src.

        _msg = hasCompose
            ? abi.encodePacked(_sendTo, _amountShared, OFTMsgCodec.addressToBytes32(_from), _composeMsg)
            : abi.encodePacked(_sendTo, _amountShared);
    }

    /**
     * @dev Allowance check and consumption against the xChain msg sender.
     *
     * @param _owner The account to check the allowance against.
     * @param _srcChainSender The address of the sender on the source chain.
     * @param _amount The amount to check the allowance for.
     */
    function _validateAndSpendAllowance(address _owner, address _srcChainSender, uint256 _amount) internal {
        if (_owner != _srcChainSender) {
            _spendAllowance(_owner, _srcChainSender, _amount);
        }
    }

    /**
     * @dev Performs a transfer with an allowance check and consumption against the xChain msg sender.
     * @dev Can only transfer to this address.
     *
     * @param _owner The account to transfer from.
     * @param _srcChainSender The address of the sender on the source chain.
     * @param _amount The amount to transfer
     */
    function _internalTransferWithAllowance(address _owner, address _srcChainSender, uint256 _amount) internal {
        _validateAndSpendAllowance(_owner, _srcChainSender, _amount);
        _transfer(_owner, address(this), _amount);
    }

    /**
     * @dev Internal function to return the current EID.
     */
    function _getChainId() internal view virtual returns (uint32) {}
}
