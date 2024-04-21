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
    DepositRepayAndRemoveCollateralFromMarketData,
    DepositAndSendForLockingData,
    IDepositData,
    LockAndParticipateData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {TapiocaOmnichainEngineCodec} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainEngineCodec.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOption} from "tapioca-periph/interfaces/tap-token/ITapiocaOption.sol";
import {IMarketHelper} from "tapioca-periph/interfaces/bar/IMarketHelper.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {Module, IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SendParamsMsg} from "tapioca-periph/interfaces/oft/ITOFT.sol";
import {SafeApprove} from "tapioca-periph/libraries/SafeApprove.sol";
import {ITOFT} from "tapioca-periph/interfaces/oft/ITOFT.sol";
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
    error Magnetar_UserMismatch();

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
        if (!cluster.isWhitelisted(0, address(data.marketHelper))) {
            revert Magnetar_TargetNotWhitelisted(address(data.marketHelper));
        }

        IMarket _market = IMarket(data.market);
        IYieldBox _yieldBox = IYieldBox(_market._yieldBox());

        uint256 assetId = _market._assetId();
        (, address assetAddress,,) = _yieldBox.assets(assetId);

        // @dev deposit to YieldBox
        if (data.depositAmount > 0) {
            data.depositAmount = _extractTokens(data.user, assetAddress, data.depositAmount);
            IERC20(assetAddress).approve(address(_yieldBox), 0);
            IERC20(assetAddress).approve(address(_yieldBox), data.depositAmount);
            _yieldBox.depositAsset(assetId, address(this), data.user, data.depositAmount, 0);
        }

        // @dev performs a repay operation for the specified market
        if (data.repayAmount > 0) {
            uint256 repayPart = helper.getBorrowPartForAmount(data.market, data.repayAmount);

            _setApprovalForYieldBox(data.market, _yieldBox);

            (Module[] memory modules, bytes[] memory calls) =
                IMarketHelper(data.marketHelper).repay(data.user, data.user, false, repayPart);

            _setApprovalForYieldBox(address(pearlmit), _yieldBox);
            _market.execute(modules, calls, true);
            _revertYieldBoxApproval(address(pearlmit), _yieldBox);
            _revertYieldBoxApproval(data.market, _yieldBox);
        }

        /**
         * @dev performs a remove collateral market operation;
         *       also withdraws if requested.
         */
        if (data.collateralAmount > 0) {
            address collateralWithdrawReceiver = data.withdrawCollateralParams.withdraw ? address(this) : data.user;
            uint256 collateralShare = _yieldBox.toShare(_market._collateralId(), data.collateralAmount, false);

            (Module[] memory modules, bytes[] memory calls) = IMarketHelper(data.marketHelper).removeCollateral(
                data.user, collateralWithdrawReceiver, collateralShare
            );
            pearlmit.approve(
                address(_yieldBox),
                _market._collateralId(),
                address(_market),
                collateralShare.toUint200(),
                (block.timestamp + 1).toUint48()
            );
            _setApprovalForYieldBox(address(pearlmit), _yieldBox);
            _market.execute(modules, calls, true);
            _revertYieldBoxApproval(address(pearlmit), _yieldBox);

            //withdraw
            if (data.withdrawCollateralParams.withdraw) {
                uint256 collateralId = _market._collateralId();
                if (data.withdrawCollateralParams.assetId != collateralId) revert Magnetar_WithdrawParamsMismatch();

                // @dev re-calculate amount
                if (collateralShare > 0) {
                    if (data.withdrawCollateralParams.compose) {
                        // allow only unwrap receiver
                        (,,, bytes memory tapComposeMsg_,) = TapiocaOmnichainEngineCodec.decodeToeComposeMsg(
                            data.withdrawCollateralParams.lzSendParams.sendParam.composeMsg
                        );

                        // it should fail at this point if data != SendParamsMsg
                        SendParamsMsg memory unwrapReceiverData = abi.decode(tapComposeMsg_, (SendParamsMsg));
                        if (unwrapReceiverData.receiver != data.user) revert Magnetar_UserMismatch();
                    }

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
