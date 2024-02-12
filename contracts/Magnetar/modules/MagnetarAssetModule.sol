// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {
    MagnetarWithdrawData,
    DepositRepayAndRemoveCollateralFromMarketData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOption} from "tapioca-periph/interfaces/tap-token/ITapiocaOption.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {MagnetarBaseModule} from "./MagnetarBaseModule.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title MagnetarAssetModule
 * @author TapiocaDAO
 * @notice Magnetar Usdo related operations
 */
contract MagnetarAssetModule is MagnetarBaseModule {
    using SafeERC20 for IERC20;

    error Magnetar_WithdrawParamsMismatch();
    error Magnetar_ActionParamsMismatch();
    error Magnetar_tOLPTokenMismatch();

    /// =====================
    /// Public
    /// =====================

    /**
     * @notice helper for deposit asset to YieldBox, repay on a market, remove collateral and withdraw
     * @dev all steps are optional:
     *         - if `depositAmount` is 0, the deposit to YieldBox step is skipped
     *         - if `repayAmount` is 0, the repay step is skipped
     *         - if `collateralAmount` is 0, the add collateral step is skipped
     *
     * @param data.market the SGL/BigBang market
     * @param data.user the user to perform the action for
     * @param data.depositAmount the amount to deposit to YieldBox
     * @param data.repayAmount the amount to repay to the market
     * @param data.collateralAmount the amount to withdraw from the market
     * @param data.withdrawCollateralParams withdraw specific params
     */
    function depositRepayAndRemoveCollateralFromMarket(DepositRepayAndRemoveCollateralFromMarketData memory data)
        public
        payable
    {
        // Check sender
        _checkSender(data.user);

        // Check target
        if (!cluster.isWhitelisted(0, address(data.market))) {
            revert Magnetar_TargetNotWhitelisted(address(data.market));
        }

        IMarket _market = IMarket(data.market);
        IYieldBox _yieldBox = IYieldBox(_market.yieldBox());

        uint256 assetId = _market.assetId();
        (, address assetAddress,,) = _yieldBox.assets(assetId);

        // @dev deposit to YieldBox
        if (data.depositAmount > 0) {
            data.depositAmount = _extractTokens(msg.sender, assetAddress, data.depositAmount);
            IERC20(assetAddress).approve(address(_yieldBox), 0);
            IERC20(assetAddress).approve(address(_yieldBox), data.depositAmount);
            _yieldBox.depositAsset(assetId, address(this), address(this), data.depositAmount, 0);
        }

        // @dev performs a repay operation for the specified market
        if (data.repayAmount > 0) {
            _setApprovalForYieldBox(data.market, _yieldBox);
            _market.repay(data.depositAmount > 0 ? address(this) : data.user, data.user, false, data.repayAmount);
            _revertYieldBoxApproval(data.market, _yieldBox);
        }

        /**
         * @dev performs a remove collateral market operation;
         *       also withdraws if requested.
         */
        if (data.collateralAmount > 0) {
            address collateralWithdrawReceiver = data.withdrawCollateralParams.withdraw ? address(this) : data.user;
            uint256 collateralShare = _yieldBox.toShare(_market.collateralId(), data.collateralAmount, false);
            _market.removeCollateral(data.user, collateralWithdrawReceiver, collateralShare);

            //withdraw
            if (data.withdrawCollateralParams.withdraw) {
                uint256 collateralId = _market.collateralId();
                if (data.withdrawCollateralParams.assetId != collateralId) revert Magnetar_WithdrawParamsMismatch();

                // @dev re-calculate amount
                if (collateralShare > 0) {
                    uint256 computedCollateral = _yieldBox.toAmount(collateralId, collateralShare, false);
                    if (computedCollateral == 0) revert Magnetar_WithdrawParamsMismatch();

                    data.withdrawCollateralParams.lzSendParams.sendParam.amountLD = computedCollateral;
                    data.withdrawCollateralParams.lzSendParams.sendParam.minAmountLD = computedCollateral;
                    _withdrawToChain(data.withdrawCollateralParams);
                }
            }
        }
    }
}
