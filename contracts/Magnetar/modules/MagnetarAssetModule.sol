// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Tapioca
import {
    MagnetarWithdrawData,
    DepositRepayAndRemoveCollateralFromMarketData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {TapiocaOmnichainEngineCodec} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainEngineCodec.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeApprove} from "tapioca-periph/libraries/SafeApprove.sol";
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
    using SafeApprove for address;
    using SafeCast for uint256;

    error Magnetar_WithdrawParamsMismatch();

    /// =====================
    /// Public
    /// =====================

    /**
     * @notice helper for deposit asset to YieldBox, repay on a market, remove collateral and withdraw
     * @dev all steps are optional:
     *         - if `depositAmount` is 0, the deposit to YieldBox step is skipped
     *         - if `repayAmount` is 0, the repay step is skipped
     *         - if `collateralAmount` is 0, the add collateral step is skipped
     * @param data.market the SGL/BigBang market
     * @param data.user the user to perform the action for
     * @param data.depositAmount the amount to deposit to YieldBox
     * @param data.repayAmount the amount to repay to the market
     * @param data.collateralAmount the amount to remove from the market
     * @param data.withdrawCollateralParams necessary data for the same chain withdrawal
     */
    function depositRepayAndRemoveCollateralFromMarket(DepositRepayAndRemoveCollateralFromMarketData memory data)
        public
        payable
    {
        /**
         * @dev validate data
         */
        _validateDepositRepayAndRemoveCollateralFromMarketData(data);

        IMarket _market = IMarket(data.market);
        IYieldBox _yieldBox = IYieldBox(_market._yieldBox());

        /**
         * @dev YieldBox approvals
         */
        _processYieldBoxApprovals(_yieldBox, data.market, true);

        /**
         * @dev deposit to YieldBox
         */
        if (data.depositAmount > 0) {
            uint256 assetId = _market._collateralId();
            (, address assetAddress,,) = _yieldBox.assets(assetId);
            data.depositAmount = _extractTokens(data.user, assetAddress, data.depositAmount);
            _depositToYb(_yieldBox, data.user, assetId, data.depositAmount);
        }

        /**
         * @dev performs a repay operation for the specified market
         */
        if (data.repayAmount > 0) {
            _market.accrue();
            _marketRepay(_market, data.marketHelper, data.repayAmount, data.user, data.user);
        }

        /**
         * @dev performs a remove collateral market operation;
         *       also withdraws if requested.
         */
        if (data.collateralAmount > 0) {
            uint256 collateralShare = _yieldBox.toShare(_market._collateralId(), data.collateralAmount, false);
            _pearlmitApprove(address(_yieldBox), _market._collateralId(), address(_market), collateralShare);
            _marketRemoveCollateral(
                _market,
                data.marketHelper,
                collateralShare,
                data.user,
                data.withdrawCollateralParams.withdraw ? address(this) : data.user
            );

            if (data.withdrawCollateralParams.withdraw) {
                /**
                 * @dev re-calculate amount after `removeCollateral` operation
                 */
                if (collateralShare > 0) {
                    uint256 computedCollateral = _yieldBox.toAmount(_market._collateralId(), collateralShare, false);
                    if (computedCollateral == 0) revert Magnetar_WithdrawParamsMismatch();

                    _withdrawHere(data.withdrawCollateralParams);
                }
            }
        }

        /**
         * @dev YieldBox reverts
         */
        _processYieldBoxApprovals(_yieldBox, data.market, false);
    }

    /// =====================
    /// Private
    /// =====================
    function _processYieldBoxApprovals(IYieldBox _yieldBox, address market, bool approve) private {
        if (market == address(0)) return;

        if (approve) {
            _setApprovalForYieldBox(market, _yieldBox);
            _setApprovalForYieldBox(address(pearlmit), _yieldBox);
        } else {
            _revertYieldBoxApproval(market, _yieldBox);
            _revertYieldBoxApproval(address(pearlmit), _yieldBox);
        }
    }

    function _validateDepositRepayAndRemoveCollateralFromMarketData(
        DepositRepayAndRemoveCollateralFromMarketData memory data
    ) private view {
        // Check sender
        _checkSender(data.user);

        // Check provided addresses
        _checkExternalData(data);

        // Check withdraw data
        _checkWithdrawData(data.withdrawCollateralParams, data.market);
    }

    function _checkExternalData(DepositRepayAndRemoveCollateralFromMarketData memory data) private view {
        _checkWhitelisted(data.market);
        _checkWhitelisted(data.marketHelper);
    }

    function _checkWithdrawData(MagnetarWithdrawData memory data, address market) private view {
        if (data.withdraw) {
            if (data.assetId != IMarket(market)._collateralId()) revert Magnetar_WithdrawParamsMismatch();
            if (data.amount == 0) revert Magnetar_WithdrawParamsMismatch();
        }
    }
}
