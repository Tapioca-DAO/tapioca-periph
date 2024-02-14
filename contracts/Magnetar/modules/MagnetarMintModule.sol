// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {MintFromBBAndLendOnSGLData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
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
 * @title MagnetarMintModule
 * @author TapiocaDAO
 * @notice Magnetar BigBang related operations
 */
contract MagnetarMintModule is MagnetarBaseModule {
    using SafeApprove for address;
    using SafeERC20 for IERC20;

    error Magnetar_ActionParamsMismatch();
    error Magnetar_tOLPTokenMismatch();

    /**
     * @notice helper to deposit mint from BB, lend on SGL, lock on tOLP and participate on tOB
     * @dev all steps are optional:
     *         - if `mintData.mint` is false, the mint operation on BB is skipped
     *             - add BB collateral to YB, add collateral on BB and borrow from BB are part of the mint operation
     *         - if `depositData.deposit` is false, the asset deposit to YB is skipped
     *         - if `lendAmount == 0` the addAsset operation on SGL is skipped
     *             - if `mintData.mint` is true, `lendAmount` will be automatically filled with the minted value
     *         - if `lockData.lock` is false, the tOLP lock operation is skipped
     *         - if `participateData.participate` is false, the tOB participate operation is skipped
     *
     * @param data.user the user to perform the operation for
     * @param data.lendAmount the amount to lend on SGL
     * @param data.mintData the data needed to mint on BB
     * @param data.depositData the data needed for asset deposit on YieldBox
     * @param data.lockData the data needed to lock on TapiocaOptionLiquidityProvision
     * @param data.participateData the data needed to perform a participate operation on TapiocaOptionsBroker
     * @param data.externalContracts the contracts' addresses used in all the operations performed by the helper
     */
    function mintFromBBAndLendOnSGL(MintFromBBAndLendOnSGLData memory data) public payable {
        // Check sender
        _checkSender(data.user);

        // Check targets
        if (data.externalContracts.bigBang != address(0)) {
            if (!cluster.isWhitelisted(0, data.externalContracts.bigBang)) {
                revert Magnetar_TargetNotWhitelisted(data.externalContracts.bigBang);
            }
        }
        if (data.externalContracts.singularity != address(0)) {
            if (!cluster.isWhitelisted(0, data.externalContracts.singularity)) {
                revert Magnetar_TargetNotWhitelisted(data.externalContracts.singularity);
            }
        }

        IMarket bigBang_ = IMarket(data.externalContracts.bigBang);
        ISingularity singularity_ = ISingularity(data.externalContracts.singularity);
        IYieldBox yieldBox_ = IYieldBox(singularity_.yieldBox());

        {
            if (data.externalContracts.singularity != address(0)) {
                _setApprovalForYieldBox(data.externalContracts.singularity, yieldBox_);
            }
            if (data.externalContracts.bigBang != address(0)) {
                _setApprovalForYieldBox(data.externalContracts.bigBang, yieldBox_);
            }
        }

        // if `mint` was requested the following actions are performed:
        //  - extracts & deposits collateral to YB
        //  - performs bigBang_.addCollateral
        //  - performs bigBang_.borrow
        if (data.mintData.mint) {
            // retrieve collateral id & address
            uint256 bbCollateralId = bigBang_.collateralId();
            (, address bbCollateralAddress,,) = yieldBox_.assets(bbCollateralId);

            // compute collateral share
            uint256 bbCollateralShare =
                yieldBox_.toShare(bbCollateralId, data.mintData.collateralDepositData.amount, false);

            // deposit collateral to YB
            if (data.mintData.collateralDepositData.deposit) {
                data.mintData.collateralDepositData.amount =
                    _extractTokens(data.user, bbCollateralAddress, data.mintData.collateralDepositData.amount);
                bbCollateralShare = yieldBox_.toShare(bbCollateralId, data.mintData.collateralDepositData.amount, false);

                bbCollateralAddress.safeApprove(address(yieldBox_), data.mintData.collateralDepositData.amount);
                yieldBox_.depositAsset(
                    bbCollateralId, address(this), address(this), data.mintData.collateralDepositData.amount, 0
                );
            }

            // add collateral to BB
            if (data.mintData.collateralDepositData.amount > 0) {
                _setApprovalForYieldBox(data.externalContracts.bigBang, yieldBox_);
                bigBang_.addCollateral(
                    data.mintData.collateralDepositData.deposit ? address(this) : data.user,
                    data.user,
                    false,
                    data.mintData.collateralDepositData.amount,
                    bbCollateralShare
                );
            }

            // mints from BB
            bigBang_.borrow(data.user, data.user, data.mintData.mintAmount);
        }

        // if `depositData.deposit`:
        //      - deposit SGL asset to YB for `data.user`
        uint256 sglAssetId = singularity_.assetId();
        (, address sglAssetAddress,,) = yieldBox_.assets(sglAssetId);
        if (data.depositData.deposit) {
            data.depositData.amount = _extractTokens(data.user, sglAssetAddress, data.depositData.amount);

            sglAssetAddress.safeApprove(address(yieldBox_), data.depositData.amount);
            yieldBox_.depositAsset(sglAssetId, address(this), data.user, data.depositData.amount, 0);
        }

        // if `lendAmount` > 0:
        //      - add asset to SGL
        uint256 fraction = 0;
        if (data.lendAmount == 0 && data.depositData.deposit) {
            data.lendAmount = data.depositData.amount;
        }
        if (data.lendAmount > 0) {
            uint256 lendShare = yieldBox_.toShare(sglAssetId, data.lendAmount, false);
            fraction = singularity_.addAsset(data.user, data.user, false, lendShare);
        }

        // if `lockData.lock`:
        //      - transfer `fraction` from data.user to `address(this)
        //      - deposits `fraction` to YB for `address(this)`
        //      - performs tOLP.lock
        uint256 tOLPTokenId = 0;
        if (data.lockData.lock) {
            if (!cluster.isWhitelisted(0, data.lockData.target)) {
                revert Magnetar_TargetNotWhitelisted(data.lockData.target);
            }
            if (data.lockData.fraction > 0) fraction = data.lockData.fraction;

            // retrieve and deposit SGLAssetId registered in tOLP
            (uint256 tOLPSglAssetId,,) = ITapiocaOptionLiquidityProvision(data.lockData.target).activeSingularities(
                data.externalContracts.singularity
            );
            if (fraction == 0) revert Magnetar_ActionParamsMismatch();

            //deposit to YieldBox
            IERC20(data.externalContracts.singularity).safeTransferFrom(data.user, address(this), fraction);
            data.externalContracts.singularity.safeApprove(address(yieldBox_), fraction);
            yieldBox_.depositAsset(tOLPSglAssetId, address(this), address(this), fraction, 0);

            _setApprovalForYieldBox(data.lockData.target, yieldBox_);
            address lockTo = data.participateData.participate ? address(this) : data.user;
            tOLPTokenId = ITapiocaOptionLiquidityProvision(data.lockData.target).lock(
                lockTo, data.externalContracts.singularity, data.lockData.lockDuration, data.lockData.amount
            );
            _revertYieldBoxApproval(data.lockData.target, yieldBox_);
        }

        // TODO improve this
        // if `participateData.participate`:
        //      - verify tOLPTokenId
        //      - performs tOB.participate
        //      - transfer `oTAPTokenId` to data.user
        if (data.participateData.participate) {
            if (!cluster.isWhitelisted(0, data.participateData.target)) {
                revert Magnetar_TargetNotWhitelisted(data.participateData.target);
            }

            // Check tOLPTokenId
            if (data.participateData.tOLPTokenId != 0) {
                if (data.participateData.tOLPTokenId != tOLPTokenId && tOLPTokenId != 0) {
                    revert Magnetar_tOLPTokenMismatch();
                }

                tOLPTokenId = data.participateData.tOLPTokenId;
            }
            if (tOLPTokenId == 0) revert Magnetar_ActionParamsMismatch();

            IERC721(data.lockData.target).approve(data.participateData.target, tOLPTokenId);
            uint256 oTAPTokenId = ITapiocaOptionBroker(data.participateData.target).participate(tOLPTokenId);

            address oTapAddress = ITapiocaOptionBroker(data.participateData.target).oTAP();
            IERC721(oTapAddress).safeTransferFrom(address(this), data.user, oTAPTokenId, "0x");
        }

        if (data.externalContracts.singularity != address(0)) {
            _revertYieldBoxApproval(data.externalContracts.singularity, yieldBox_);
        }
        if (data.externalContracts.bigBang != address(0)) {
            _revertYieldBoxApproval(data.externalContracts.bigBang, yieldBox_);
        }
    }
}
