// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Tapioca
import {DepositAddCollateralAndBorrowFromMarketData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IMarketHelper} from "tapioca-periph/interfaces/bar/IMarketHelper.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IMarket, Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
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

    error MagnetarCollateralModule_ComposeMsgNotAllowed();

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
     * @param data.withdrawParams necessary data for the same chain or the cross-chain withdrawal
     */
    function depositAddCollateralAndBorrowFromMarket(DepositAddCollateralAndBorrowFromMarketData memory data)
        public
        payable
    {
        // Check sender
        _checkSender(data.user);

        // Check
        if (!cluster.isWhitelisted(0, data.market)) {
            revert Magnetar_TargetNotWhitelisted(data.market);
        }
        if (!cluster.isWhitelisted(0, data.marketHelper)) {
            revert Magnetar_TargetNotWhitelisted(data.marketHelper);
        }

        IMarket market_ = IMarket(data.market);
        IYieldBox yieldBox_ = IYieldBox(market_.yieldBox());

        uint256 collateralId = market_.collateralId();
        (, address collateralAddress,,) = yieldBox_.assets(collateralId);

        uint256 _share = yieldBox_.toShare(collateralId, data.collateralAmount, false);

        _setApprovalForYieldBox(address(pearlmit), yieldBox_);

        // deposit to YieldBox
        if (data.deposit) {
            // transfers tokens from sender or from the user to this contract
            data.collateralAmount = _extractTokens(data.user, collateralAddress, data.collateralAmount);
            _share = yieldBox_.toShare(collateralId, data.collateralAmount, false);

            // deposit to YieldBox
            IERC20(collateralAddress).approve(address(yieldBox_), 0);
            IERC20(collateralAddress).approve(address(yieldBox_), data.collateralAmount);
            yieldBox_.depositAsset(collateralId, address(this), data.user, data.collateralAmount, 0);
        }

        // performs .addCollateral on data.market
        if (data.collateralAmount > 0) {
            _setApprovalForYieldBox(data.market, yieldBox_);

            (Module[] memory modules, bytes[] memory calls) = IMarketHelper(data.marketHelper).addCollateral(
                data.user, data.user, false, data.collateralAmount, _share
            );
            pearlmit.approve(
                address(yieldBox_),
                collateralId,
                address(market_),
                _share.toUint200(),
                (block.timestamp + 1).toUint48()
            );
            market_.execute(modules, calls, true);
            _revertYieldBoxApproval(data.market, yieldBox_);
        }

        // performs .borrow on data.market
        // if `withdraw` it uses `withdrawTo` to withdraw assets on the same chain or to another one
        if (data.borrowAmount > 0) {
            address borrowReceiver = data.withdrawParams.withdraw ? address(this) : data.user;

            (Module[] memory modules, bytes[] memory calls) =
                IMarketHelper(data.marketHelper).borrow(data.user, borrowReceiver, data.borrowAmount);

            uint256 borrowShare = yieldBox_.toShare(market_.assetId(), data.borrowAmount, false);
            pearlmit.approve(
                address(yieldBox_),
                market_.assetId(),
                address(market_),
                borrowShare.toUint200(),
                (block.timestamp + 1).toUint48()
            );
            market_.execute(modules, calls, true);

            if (data.withdrawParams.withdraw) {
                // asset is USDO which doesn't have unwrap
                if (data.withdrawParams.compose) revert MagnetarCollateralModule_ComposeMsgNotAllowed();
                _withdrawToChain(data.withdrawParams);
            }
        }

        _revertYieldBoxApproval(address(pearlmit), yieldBox_);
        _revertYieldBoxApproval(data.market, yieldBox_);
    }
}
