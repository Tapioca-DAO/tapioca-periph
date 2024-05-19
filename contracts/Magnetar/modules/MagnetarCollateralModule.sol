// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Tapioca
import {
    DepositAddCollateralAndBorrowFromMarketData,
    MagnetarWithdrawData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IMarket, Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {SafeApprove} from "tapioca-periph/libraries/SafeApprove.sol";
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
 * @title MagnetarCollateralModule
 * @author TapiocaDAO
 * @notice Magnetar collateral related operations
 */
contract MagnetarCollateralModule is MagnetarBaseModule {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeApprove for address;

    error MagnetarCollateralModule_UnwrapNotAllowed();
    error Magnetar_WithdrawParamsMismatch();

    constructor(IPearlmit pearlmit) MagnetarBaseModule(pearlmit) {}

    /**
     * @notice helper for deposit to YieldBox, add collateral to a market, borrow from the same market and withdraw
     * @dev all operations are optional:
     *         - if `deposit` is false it will skip the deposit to YieldBox step
     *         - if `withdraw` is false it will skip the withdraw step
     *         - if `collateralAmount == 0` it will skip the add collateral step
     *         - if `borrowAmount == 0` it will skip the borrow step
     *     - the amount deposited to YieldBox is `collateralAmount`
     *
     * @param data.market the SGL/BigBang market
     * @param data.user the user to perform the action for
     * @param data.collateralAmount the collateral amount to add
     * @param data.borrowAmount the borrow amount
     * @param data.deposit true/false flag for the deposit to YieldBox step
     * @param data.withdrawParams necessary data for the same chain withdrawal
     */
    function depositAddCollateralAndBorrowFromMarket(DepositAddCollateralAndBorrowFromMarketData memory data)
        public
        payable
    {
        /**
         * @dev validate data
         */
        _validateDepositAddCollateralAndBorrowFromMarket(data);

        IMarket _market = IMarket(data.market);
        IYieldBox _yieldBox = IYieldBox(_market._yieldBox());

        /**
         * @dev YieldBox approvals
         */
        _processYieldBoxApprovals(_yieldBox, data.market, true);

        uint256 collateralId = _market._collateralId();

        /**
         * @dev deposit to YieldBox
         */
        if (data.deposit) {
            (, address collateralAddress,,) = _yieldBox.assets(collateralId);
            data.collateralAmount = _extractTokens(data.user, collateralAddress, data.collateralAmount);

            _depositToYb(_yieldBox, data.user, collateralId, data.collateralAmount);
        }

        /**
         * @dev performs .addCollateral on data.market
         */
        if (data.collateralAmount > 0) {
            uint256 _share = _yieldBox.toShare(collateralId, data.collateralAmount, false);

            _pearlmitApprove(address(_yieldBox), collateralId, address(_market), _share);
            _marketAddCollateral(_market, data.marketHelper, _share, data.user, data.user);
        }

        /**
         * @dev performs .borrow on data.market
         *      if `withdraw` it uses `_withdrawHere` to withdraw assets on the same chain
         */
        if (data.borrowAmount > 0) {
            uint256 borrowShare = _yieldBox.toShare(_market._assetId(), data.borrowAmount, false);
            _pearlmitApprove(address(_yieldBox), _market._assetId(), address(_market), borrowShare);
            _marketBorrow(
                _market,
                data.marketHelper,
                data.borrowAmount,
                data.user,
                data.withdrawParams.withdraw ? address(this) : data.user
            );

            // data validated in `_validateDepositAddCollateralAndBorrowFromMarket`
            if (data.withdrawParams.withdraw) _withdrawHere(data.withdrawParams);
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

    function _validateDepositAddCollateralAndBorrowFromMarket(DepositAddCollateralAndBorrowFromMarketData memory data)
        private
        view
    {
        // Check sender
        _checkSender(data.user);

        // Check provided addresses
        _checkExternalData(data);

        // Check withdraw data
        _checkWithdrawData(data.withdrawParams, data.market);
    }

    function _checkExternalData(DepositAddCollateralAndBorrowFromMarketData memory data) private view {
        _checkWhitelisted(data.market);
        _checkWhitelisted(data.marketHelper);
    }

    function _checkWithdrawData(MagnetarWithdrawData memory data, address market) private view {
        if (data.withdraw) {
            // USDO doesn't have unwrap
            if (data.unwrap) revert MagnetarCollateralModule_UnwrapNotAllowed();
            if (data.assetId != IMarket(market)._assetId()) revert Magnetar_WithdrawParamsMismatch();
            if (data.amount == 0) revert Magnetar_WithdrawParamsMismatch();
        }
    }
}
