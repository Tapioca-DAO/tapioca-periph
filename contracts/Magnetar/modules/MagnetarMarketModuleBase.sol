// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//TAPIOCA
import {IYieldBox} from "tapioca-periph/interfaces/yieldBox/IYieldBox.sol";
import {MagnetarYieldboxModule} from "./MagnetarYieldboxModule.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {MagnetarV2Storage} from "../MagnetarV2Storage.sol";

abstract contract MagnetarMarketModuleBase is MagnetarV2Storage {
    using SafeERC20 for IERC20;

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error NotValid();
    error ExtractTokenFail(); // failed to extract tokens from sender or user. See `_extractTokens()`

    // ************************* //
    // *** INTERNAL METHODS ***  //
    // ************************* //

    /**
     * @dev `_withdraw` calldata
     */
    struct _WithdrawData {
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
     *
     */
    function _withdraw(_WithdrawData memory _data) internal {
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
        _yieldBoxModule__WithdrawToChain(withdrawToChainData);
    }

    /**
     * @dev Call internally the withdrawToChain method of the YieldBox module.
     */
    function _yieldBoxModule__WithdrawToChain(MagnetarYieldboxModule.WithdrawToChainData memory _data) internal {
        // Prepare the call to the withdrawToChain method.
        // Most fields are not needed, we just to pass the encoded data
        Call memory call;
        call.call = abi.encodeWithSelector(MagnetarYieldboxModule.withdrawToChain.selector, _data);
        _executeModule(Module.Yieldbox, call);
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
