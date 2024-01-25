// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LzLib} from "tapioca-periph/tmp/LzLib.sol";

//TAPIOCA
import {ITapiocaOFT} from "tapioca-periph/interfaces/tap-token/ITapiocaOFT.sol";
import {ICommonData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {ICommonOFT} from "tapioca-periph/interfaces/common/ICommonOFT.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldBox/IYieldBox.sol";
import {ISendFrom} from "tapioca-periph/interfaces/common/ISendFrom.sol";
import {MagnetarYieldboxModule} from "./MagnetarYieldboxModule.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {MagnetarV2Storage} from "../MagnetarV2Storage.sol";

/// @dev We need Ownable to map MagnetarV2 storage layout
abstract contract MagnetarMarketModuleBase is Ownable, MagnetarV2Storage {
    using SafeERC20 for IERC20;

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error NotValid();
    error ExtractTokenFail(); // failed to extract tokens from sender or user. See `_extractTokens()`
    error GasMismatch(uint256 expected, uint256 received);

    // ************************* //
    // *** INTERNAL METHODS ***  //
    // ************************* //

    /**
     * @dev `_withdraw` calldata
     */
    struct _WithdrawPrepareData {
        address from;
        bytes withdrawData;
        IMarket market;
        IYieldBox yieldBox;
        uint256 amount;
        bool withdrawCollateral;
        uint256 valueAmount;
        bool unwrap;
        address payable refundAddress;
        address zroPaymentAddress;
    }

    /**
     * @dev Performs a YieldBox withdrawal.
     * Can withdraw asset or collateral, on the same chain or on another one.
     */
    function _withdrawPrepare(_WithdrawPrepareData memory _data) internal {
        if (_data.withdrawData.length == 0) revert NotValid();
        (bool withdrawOnOtherChain, uint16 destChain, bytes32 receiver, bytes memory adapterParams) =
            abi.decode(_data.withdrawData, (bool, uint16, bytes32, bytes));

        // Prepare the call to the withdrawToChain method.
        // Most fields are not needed, we just to pass the encoded data
        MagnetarYieldboxModule.WithdrawToChainData memory withdrawToChainData = MagnetarYieldboxModule
            .WithdrawToChainData({
            yieldBox: _data.yieldBox,
            from: _data.from,
            assetId: _data.withdrawCollateral ? _data.market.collateralId() : _data.market.assetId(),
            dstChainId: withdrawOnOtherChain ? destChain : 0,
            receiver: receiver,
            amount: _data.amount,
            adapterParams: adapterParams,
            refundAddress: _data.refundAddress,
            gas: _data.valueAmount,
            unwrap: _data.unwrap,
            zroPaymentAddress: _data.zroPaymentAddress
        });
        _withdrawToChain(withdrawToChainData);
    }

    /**
     * @dev Same as `MagnetarYieldboxModule.withdrawToChain()` but with a different signature.
     * Only difference is we don't check `_checkSender(_data.from)`
     * @dev This is supposed to get called only by `MagnetarMarketModuleBase._withdraw()` or its inheritors.
     * Be carful when calling on its inheritors.
     *
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
    function _withdrawToChain(MagnetarYieldboxModule.WithdrawToChainData memory _data) internal {
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
        private
    {
        yieldBox.withdraw(assetId, from, LzLib.bytes32ToAddress(receiver), amount, 0);
    }

    function _setApprovalForYieldBox(address target, IYieldBox yieldBox) internal {
        bool isApproved = yieldBox.isApprovedForAll(address(this), target);
        if (!isApproved) {
            yieldBox.setApprovalForAll(target, true);
        }
    }

    function _revertYieldBoxApproval(address target, IYieldBox yieldBox) internal {
        bool isApproved = yieldBox.isApprovedForAll(address(this), address(target));
        if (isApproved) {
            yieldBox.setApprovalForAll(address(target), false);
        }
    }

    /**
     * @dev Extracts ERC20 tokens from `_from` to this contract.
     */
    function _extractTokens(address _from, address _token, uint256 _amount) internal returns (uint256) {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        if (balanceAfter <= balanceBefore) revert ExtractTokenFail();
        return balanceAfter - balanceBefore;
    }
}
