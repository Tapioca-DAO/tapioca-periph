// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";
import {LzLib} from "tapioca-periph/tmp/LzLib.sol";

// Tapioca
import {ITapiocaOFT} from "tapioca-periph/interfaces/tap-token/ITapiocaOFT.sol";
import {ICommonData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {ICommonOFT} from "tapioca-periph/interfaces/common/ICommonOFT.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldBox/IYieldBox.sol";
import {ISendFrom} from "tapioca-periph/interfaces/common/ISendFrom.sol";
import {MagnetarV2Storage} from "../MagnetarV2Storage.sol";

contract MagnetarYieldboxModule is MagnetarV2Storage {
    error GasMismatch(uint256 expected, uint256 received);

    /// @dev Parse a burst call
    fallback() external payable {
        Call memory call = abi.decode(msg.data, (Call));
        bytes4 funcSig = bytes4(BytesLib.slice(call.call, 0, 4));
        bytes memory callWithoutSelector = BytesLib.slice(call.call, 4, call.call.length);

        if (funcSig == IYieldBox.depositAsset.selector) {
            depositAsset(call.target, abi.decode(callWithoutSelector, (YieldBoxDepositData)));
        }
        if (funcSig == this.withdrawToChain.selector) {
            withdrawToChain(abi.decode(callWithoutSelector, (WithdrawToChainData)));
        }
    }

    /**
     * @dev Executes a call to an address, optionally reverting on failure. Make sure to sanitize prior to calling.
     */
    function _executeCall(address _target, bytes calldata _actionCalldata, uint256 _actionValue, bool _allowFailure)
        internal
    {
        (bool success, bytes memory returnData) = _target.call{value: _actionValue}(_actionCalldata);

        if (!success && !_allowFailure) {
            _getRevertMsg(returnData);
        }
    }

    /**
     * @dev `depositAsset` calldata
     */
    struct YieldBoxDepositData {
        uint256 assetId;
        address from;
        address to;
        uint256 amount;
        uint256 share;
    }

    /**
     * @dev Deposit asset to YieldBox..
     * @param _target YieldBox address
     * @param _data The data without the func sig
     */
    function depositAsset(address _target, YieldBoxDepositData memory _data) public {
        _checkSender(_data.from);
        if (!cluster.isWhitelisted(0, _target)) {
            // 0 means current chain
            revert TargetNotWhitelisted(_target);
        }
        IYieldBox(_target).depositAsset(_data.assetId, _data.from, _data.to, _data.amount, _data.share);
    }

    /**
     * @dev `withdrawToChain` calldata
     */
    struct WithdrawToChainData {
        IYieldBox yieldBox;
        address from;
        uint256 assetId;
        uint16 dstChainId;
        bytes32 receiver;
        uint256 amount;
        bytes adapterParams;
        address payable refundAddress;
        uint256 gas;
        bool unwrap;
        address zroPaymentAddress;
    }

    /**
     * @notice performs a withdraw operation
     * @dev it can withdraw on the current chain or it can send it to another one
     *     - if `dstChainId` is 0 performs a same-chain withdrawal
     *          - all parameters except `yieldBox`, `from`, `assetId` and `amount` or `share` are ignored
     *     - if `dstChainId` is NOT 0, the method requires gas for the `sendFrom` operation
     *
     * @param _data.yieldBox the YieldBox address
     * @param _data.from user to withdraw from
     * @param _data.assetId the YieldBox asset id to withdraw
     * @param _data.dstChainId LZ chain id to withdraw to
     * @param _data.receiver the receiver on the destination chain
     * @param _data.amount the amount to withdraw
     * @param _data.adapterParams LZ adapter params
     * @param _data.refundAddress the LZ refund address which receives the gas not used in the process
     * @param _data.gas the amount of gas to use for sending the asset to another layer
     * @param _data.unwrap if withdrawn asset is a TOFT, it can be unwrapped on destination
     * @param _data.zroPaymentAddress ZRO payment address
     */
    function withdrawToChain(WithdrawToChainData memory _data) public payable {
        _checkSender(_data.from);
        if (!cluster.isWhitelisted(cluster.lzChainId(), address(_data.yieldBox))) {
            revert TargetNotWhitelisted(address(_data.yieldBox));
        }

        // perform a same chain withdrawal
        if (_data.dstChainId == 0) {
            _withdrawOnThisChain(_data.yieldBox, _data.assetId, _data.from, _data.receiver, _data.amount);
            return;
        }

        if (msg.value > 0) {
            if (msg.value != _data.gas) revert GasMismatch(_data.gas, msg.value);
        }
        // perform a cross chain withdrawal
        (, address asset,,) = _data.yieldBox.assets(_data.assetId);
        if (!cluster.isWhitelisted(cluster.lzChainId(), address(asset))) {
            revert TargetNotWhitelisted(address(asset));
        }

        // withdraw from YieldBox
        _data.yieldBox.withdraw(_data.assetId, _data.from, address(this), _data.amount, 0);

        // build LZ params
        bytes memory adapterParams;
        ICommonOFT.LzCallParams memory callParams = ICommonOFT.LzCallParams({
            refundAddress: _data.refundAddress,
            zroPaymentAddress: _data.zroPaymentAddress,
            adapterParams: ISendFrom(address(asset)).useCustomAdapterParams() ? adapterParams : adapterParams
        });

        // sends the asset to another layer
        if (_data.unwrap) {
            ICommonData.IApproval[] memory approvals = new ICommonData.IApproval[](0);
            try ITapiocaOFT(address(asset)).sendFromWithParams{value: _data.gas}(
                address(this), _data.dstChainId, _data.receiver, _data.amount, callParams, true, approvals, approvals
            ) {} catch {
                _withdrawOnThisChain(_data.yieldBox, _data.assetId, _data.from, _data.receiver, _data.amount);
            }
        } else {
            try ISendFrom(address(asset)).sendFrom{value: _data.gas}(
                address(this), _data.dstChainId, _data.receiver, _data.amount, callParams
            ) {} catch {
                _withdrawOnThisChain(_data.yieldBox, _data.assetId, _data.from, _data.receiver, _data.amount);
            }
        }
    }

    /**
     * @notice withdraws an asset from a YieldBox on the current chain
     * @param yieldBox YieldBox address
     * @param assetId YieldBox asset id
     * @param from user to withdraw from
     * @param receiver the receiver on the destination chain
     * @param amount the amount to withdraw
     */
    function _withdrawOnThisChain(IYieldBox yieldBox, uint256 assetId, address from, bytes32 receiver, uint256 amount)
        internal
    {
        yieldBox.withdraw(assetId, from, LzLib.bytes32ToAddress(receiver), amount, 0);
    }
}
