// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {IMessagingChannel} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessagingChannel.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {
    PrepareLzCallData,
    PrepareLzCallReturn,
    ComposeMsgData
} from "tapioca-periph/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {TapiocaOmnichainEngineHelper} from
    "tapioca-periph/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {ITapiocaOmnichainEngine, LZSendParam} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarWithdrawData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IOftSender} from "tapioca-periph/interfaces/oft/IOftSender.sol";
import {IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {MagnetarStorage} from "../MagnetarStorage.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract MagnetarBaseModule is Ownable, MagnetarStorage {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    error Magnetar_GasMismatch(uint256 expected, uint256 received);
    error Magnetar_TargetNotWhitelisted(address target);
    error Magnetar_ExtractTokenFail();

    constructor() MagnetarStorage(IPearlmit(address(0))) {}

    /// =====================
    /// Internal
    /// =====================
    function _withdrawToChain(MagnetarWithdrawData memory data) internal {
        if (!cluster.isWhitelisted(0, address(data.yieldBox))) {
            revert Magnetar_TargetNotWhitelisted(address(data.yieldBox));
        }
        IYieldBox _yieldBox = IYieldBox(data.yieldBox);
        (, address asset,,) = _yieldBox.assets(data.assetId);

        // perform a same chain withdrawal
        if (data.lzSendParams.sendParam.dstEid == 0) {
            _withdrawHere(_yieldBox, data.assetId, data.lzSendParams.sendParam.to, data.lzSendParams.sendParam.amountLD);
            return;
        } 

        uint32 srcEid = IMessagingChannel(IOftSender(asset).endpoint()).eid();
        if (data.lzSendParams.sendParam.dstEid == srcEid) {
            _withdrawHere(_yieldBox, data.assetId, data.lzSendParams.sendParam.to, data.lzSendParams.sendParam.amountLD);
            return;
        }

        // perform a cross chain withdrawal
        if (!cluster.isWhitelisted(0, asset)) {
            revert Magnetar_TargetNotWhitelisted(asset);
        }

        _yieldBox.withdraw(data.assetId, address(this), address(this), data.lzSendParams.sendParam.amountLD, 0);
        // TODO: decide about try-catch here
        if (data.compose) {
            _lzCustomWithdraw(
                asset,
                data.lzSendParams,
                data.sendGas,
                data.sendVal,
                data.composeGas,
                data.composeVal,
                data.composeMsgType
            );
        } else {
            _lzWithdraw(asset, data.lzSendParams, data.sendGas, data.sendVal);
        }
    }

    function _setApprovalForYieldBox(address _target, IYieldBox _yieldBox) internal {
        bool isApproved = _yieldBox.isApprovedForAll(address(this), _target);
        if (!isApproved) {
            _yieldBox.setApprovalForAll(_target, true);
        }
    }

    function _revertYieldBoxApproval(address _target, IYieldBox _yieldBox) internal {
        bool isApproved = _yieldBox.isApprovedForAll(address(this), _target);
        if (isApproved) {
            _yieldBox.setApprovalForAll(_target, false);
        }
    }

    function _extractTokens(address _from, address _token, uint256 _amount) internal returns (uint256) {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        // IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        bool isErr = pearlmit.transferFromERC20(_from, address(this), address(_token), _amount);
        if (isErr) revert Magnetar_ExtractTokenFail();
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        if (balanceAfter <= balanceBefore) revert Magnetar_ExtractTokenFail();
        return balanceAfter - balanceBefore;
    }

    /// =====================
    /// Private
    /// =====================
    function _withdrawHere(IYieldBox _yieldBox, uint256 _assetId, bytes32 _to, uint256 _amount) private {
        _yieldBox.withdraw(_assetId, address(this), OFTMsgCodec.bytes32ToAddress(_to), _amount, 0);
    }

    function _lzWithdraw(address _asset, LZSendParam memory _lzSendParam, uint128 _lzSendGas, uint128 _lzSendVal)
        private
    {
        PrepareLzCallReturn memory prepareLzCallReturn = _prepareLzSend(_asset, _lzSendParam, _lzSendGas, _lzSendVal);

        if (msg.value < prepareLzCallReturn.msgFee.nativeFee) {
            revert Magnetar_GasMismatch(prepareLzCallReturn.msgFee.nativeFee, msg.value);
        }

        IOftSender(_asset).sendPacket{value: prepareLzCallReturn.msgFee.nativeFee}(
            prepareLzCallReturn.lzSendParam, prepareLzCallReturn.composeMsg
        );
    }

    function _lzCustomWithdraw(
        address _asset,
        LZSendParam memory _lzSendParam,
        uint128 _lzSendGas,
        uint128 _lzSendVal,
        uint128 _lzComposeGas,
        uint128 _lzComposeVal,
        uint16 _lzComposeMsgType
    ) private {
        PrepareLzCallReturn memory prepareLzCallReturn = _prepareLzSend(_asset, _lzSendParam, _lzSendGas, _lzSendVal);

        TapiocaOmnichainEngineHelper _toeHelper = new TapiocaOmnichainEngineHelper();
        PrepareLzCallReturn memory prepareLzCallReturn2 = _toeHelper.prepareLzCall(
            ITapiocaOmnichainEngine(_asset),
            PrepareLzCallData({
                dstEid: _lzSendParam.sendParam.dstEid,
                recipient: _lzSendParam.sendParam.to,
                amountToSendLD: 0,
                minAmountToCreditLD: 0,
                msgType: _lzComposeMsgType,
                composeMsgData: ComposeMsgData({
                    index: 0,
                    gas: _lzComposeGas,
                    value: prepareLzCallReturn.msgFee.nativeFee.toUint128(),
                    data: _lzSendParam.sendParam.composeMsg,
                    prevData: bytes(""),
                    prevOptionsData: bytes("")
                }),
                lzReceiveGas: _lzSendGas + _lzComposeGas,
                lzReceiveValue: _lzComposeVal,
                refundAddress: _lzSendParam.refundAddress
            })
        );

        if (msg.value < prepareLzCallReturn2.msgFee.nativeFee) {
            revert Magnetar_GasMismatch(prepareLzCallReturn2.msgFee.nativeFee, msg.value);
        }

        IOftSender(_asset).sendPacket{value: prepareLzCallReturn2.msgFee.nativeFee}(
            prepareLzCallReturn2.lzSendParam, prepareLzCallReturn2.composeMsg
        );
    }

    function _prepareLzSend(address _asset, LZSendParam memory _lzSendParam, uint128 _lzSendGas, uint128 _lzSendVal)
        private
        returns (PrepareLzCallReturn memory prepareLzCallReturn)
    {
        TapiocaOmnichainEngineHelper _toeHelper = new TapiocaOmnichainEngineHelper();
        prepareLzCallReturn = _toeHelper.prepareLzCall(
            ITapiocaOmnichainEngine(_asset),
            PrepareLzCallData({
                dstEid: _lzSendParam.sendParam.dstEid,
                recipient: _lzSendParam.sendParam.to,
                amountToSendLD: _lzSendParam.sendParam.amountLD,
                minAmountToCreditLD: _lzSendParam.sendParam.minAmountLD,
                msgType: 1, // SEND
                composeMsgData: ComposeMsgData({
                    index: 0,
                    gas: 0,
                    value: 0,
                    data: bytes(""),
                    prevData: bytes(""),
                    prevOptionsData: bytes("")
                }),
                lzReceiveGas: _lzSendGas,
                lzReceiveValue: _lzSendVal,
                refundAddress: _lzSendParam.refundAddress
            })
        );
    }
}
