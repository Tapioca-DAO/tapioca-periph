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
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOption} from "tapioca-periph/interfaces/tap-token/ITapiocaOption.sol";
import {IMarketHelper} from "tapioca-periph/interfaces/bar/IMarketHelper.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {Module, IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
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
contract MagnetarAssetCommonModule is MagnetarBaseModule {
    using SafeERC20 for IERC20;
    using SafeApprove for address;

    error Magnetar_ActionParamsMismatch();
    error Magnetar_tOLPTokenMismatch();

    function _wrapSglReceipt(
        IYieldBox yieldBox,
        address sgl,
        address user,
        uint256 fraction,
        uint256 assetId,
        bool ybDeposit,
        address receiver
    ) internal returns (uint256 toftAmount) {
        IERC20(sgl).safeTransferFrom(user, address(this), fraction);

        (, address tReceiptAddress,,) = yieldBox.assets(assetId);

        IERC20(sgl).approve(tReceiptAddress, fraction);
        toftAmount = ITOFT(tReceiptAddress).wrap(address(this), address(this), fraction);

        if (ybDeposit) {
            IERC20(tReceiptAddress).safeApprove(address(yieldBox), toftAmount);
            yieldBox.depositAsset(assetId, address(this), receiver, toftAmount, 0);
        } else {
            IERC20(tReceiptAddress).safeTransfer(receiver, toftAmount);
        }
    }

    function _depositYBLendSGL(
        IDepositData memory depositData,
        address singularityAddress,
        IYieldBox yieldBox_,
        address user,
        uint256 lendAmount
    ) internal returns (uint256 fraction) {
        if (singularityAddress != address(0)) {
            if (!cluster.isWhitelisted(0, singularityAddress)) {
                revert Magnetar_TargetNotWhitelisted(singularityAddress);
            }
            _setApprovalForYieldBox(singularityAddress, yieldBox_);

            IMarket singularity_ = IMarket(singularityAddress);

            // if `depositData.deposit`:
            //      - deposit SGL asset to YB for `user`
            uint256 sglAssetId = singularity_._assetId();
            (, address sglAssetAddress,,) = yieldBox_.assets(sglAssetId);
            if (depositData.deposit) {
                depositData.amount = _extractTokens(user, sglAssetAddress, depositData.amount);

                sglAssetAddress.safeApprove(address(yieldBox_), depositData.amount);
                yieldBox_.depositAsset(sglAssetId, address(this), user, depositData.amount, 0);
            }

            // if `lendAmount` > 0:
            //      - add asset to SGL
            fraction = 0;
            if (lendAmount > 0) {
                uint256 lendShare = yieldBox_.toShare(sglAssetId, lendAmount, false);
                fraction = ISingularity(singularityAddress).addAsset(user, user, false, lendShare);
            }

            _revertYieldBoxApproval(singularityAddress, yieldBox_);
        }
    }
}
