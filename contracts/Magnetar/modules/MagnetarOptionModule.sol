// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {
    ExitPositionAndRemoveCollateralData,
    ICommonExternalContracts,
    IRemoveAndRepay,
    LockAndParticipateData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOption} from "tapioca-periph/interfaces/tap-token/ITapiocaOption.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IMarket, Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
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
 * @title MagnetarOptionModule
 * @author TapiocaDAO
 * @notice Magnetar options related operations
 */
contract MagnetarOptionModule is MagnetarBaseModule {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    error Magnetar_ComposeMsgNotAllowed();

    constructor(IPearlmit pearlmit, address _toeHelper) MagnetarBaseModule(pearlmit, _toeHelper) {}

    /**
     * @notice helper to perform tOLP.lock(...) and tOB.participate(...)
     * @param data.user the user to perform the operation for
     * @param data.singularity the SGL address
     * @param data.fraction the amount to lock
     * @param data.lockData the data needed to lock on tOB
     * @param data.participateData the data needed to participate on tOLP
     */
    function lockAndParticipate(LockAndParticipateData memory data) public payable {
        /**
         * @dev validate data
         */
        _validateLockAndParticipate(data);

        /**
         * @dev if `lockData.lock`:
         *          - transfer `fraction` from data.user to `address(this)
         *          - deposits `fraction` to YB for `address(this)`
         *          - performs tOLP.lock
         */
        uint256 tOLPTokenId;
        if (data.lockData.lock) {
            tOLPTokenId = _lock(data);
        }

        /**
         * @dev if `participateData.participate`:
         *          - verify tOLPTokenId
         *          - performs tOB.participate
         *          - transfer `oTAPTokenId` to data.user
         */
        if (data.participateData.participate) {
            _participate(data, tOLPTokenId);
        }
    }

    function _lock(LockAndParticipateData memory data) private returns (uint256 tOLPTokenId) {
        IMarket _singularity = IMarket(data.singularity);
        IYieldBox _yieldBox = IYieldBox(_singularity._yieldBox());

        uint256 _fraction = data.lockData.fraction;

        // use requested value
        if (_fraction == 0) revert Magnetar_ActionParamsMismatch();

        // retrieve and deposit SGLAssetId registered in tOLP
        (uint256 tOLPSglAssetId,,,) =
            ITapiocaOptionLiquidityProvision(data.lockData.target).activeSingularities(data.singularity);

        _fraction = _extractTokens(data.user, data.singularity, _fraction);
        _depositToYb(_yieldBox, address(this), tOLPSglAssetId, _fraction);

        _pearlmitApprove(address(_yieldBox), tOLPSglAssetId, data.lockData.target, data.lockData.amount);
        _yieldBox.setApprovalForAll(address(pearlmit), true);

        tOLPTokenId = ITapiocaOptionLiquidityProvision(data.lockData.target).lock(
            data.participateData.participate ? address(this) : data.user,
            data.singularity,
            data.lockData.lockDuration,
            data.lockData.amount
        );

        _yieldBox.setApprovalForAll(address(pearlmit), false);
    }

    function _participate(LockAndParticipateData memory data, uint256 tOLPTokenId) private {
        // validate token ids
        if (tOLPTokenId == 0 && data.participateData.tOLPTokenId == 0) revert Magnetar_ActionParamsMismatch();
        if (
            data.participateData.tOLPTokenId != tOLPTokenId && tOLPTokenId != 0 && data.participateData.tOLPTokenId != 0
        ) {
            revert Magnetar_tOLPTokenMismatch();
        }

        if (data.participateData.tOLPTokenId != 0) tOLPTokenId = data.participateData.tOLPTokenId;

        // transfer NFT here in case `_lock` wasn't called
        // otherwise NFT should be already in Magnetar
        if (!data.lockData.lock) {
            bool isErr = pearlmit.transferFromERC721(data.user, address(this), data.lockData.target, tOLPTokenId);
            if (isErr) revert Magnetar_ExtractTokenFail();
        }

        pearlmit.approve(
            721, data.lockData.target, tOLPTokenId, data.participateData.target, 1, block.timestamp.toUint48()
        );
        IERC721(data.lockData.target).approve(address(pearlmit), tOLPTokenId);
        uint256 oTAPTokenId = ITapiocaOptionBroker(data.participateData.target).participate(tOLPTokenId);

        address oTapAddress = ITapiocaOptionBroker(data.participateData.target).oTAP();
        IERC721(oTapAddress).safeTransferFrom(address(this), data.user, oTAPTokenId, "");
    }

    /**
     * @notice helper to exit from  tOB, unlock from tOLP, remove from SGL, repay on BB, remove collateral from BB and withdraw
     * @dev all steps are optional:
     *         - if `removeAndRepayData.exitData.exit` is false, the exit operation is skipped
     *         - if `removeAndRepayData.unlockData.unlock` is false, the unlock operation is skipped
     *         - if `removeAndRepayData.removeAssetFromSGL` is false, the removeAsset operation is skipped
     *         - if `!removeAndRepayData.assetWithdrawData.withdraw && removeAndRepayData.repayAssetOnBB`, the repay operation is performed
     *         - if `removeAndRepayData.removeCollateralFromBB` is false, the rmeove collateral is skipped
     *     - the helper can either stop at the remove asset from SGL step or it can continue until is removes & withdraws collateral from BB
     *         - removed asset can be withdrawn by providing `removeAndRepayData.assetWithdrawData`
     *     - BB collateral can be removed by providing `removeAndRepayData.collateralWithdrawData`
     */
    function exitPositionAndRemoveCollateral(ExitPositionAndRemoveCollateralData memory data) public payable {
        /**
         * @dev validate data
         */
        _validateExitPositionAndRemoveCollateral(data);

        /**
         * @dev YieldBox approvals
         */
        _processYieldBoxApprovals(data.externalData.bigBang, data.externalData.singularity, true);

        /**
         * @dev if `removeAndRepayData.exitData.exit` the following operations are performed
         *          - if ownerOfTapTokenId is user, transfers the oTAP token id to this contract
         *          - tOB.exitPosition
         *          - if `!removeAndRepayData.unlockData.unlock`, transfer the obtained tokenId to the user
         */
        uint256 tOLPId = 0;
        if (data.removeAndRepayData.exitData.exit) {
            tOLPId = _exit(data);
        }

        /**
         * @dev performs a tOLP.unlock operation
         */
        if (data.removeAndRepayData.unlockData.unlock) {
            _unlock(data, tOLPId);
        }

        /**
         * @dev if `data.removeAndRepayData.removeAssetFromSGL` performs the follow operations:
         *          - removeAsset from SGL
         *          - if `data.removeAndRepayData.assetWithdrawData.withdraw` withdraws by using the `withdrawTo` operation
         */
        if (data.removeAndRepayData.removeAssetFromSGL) {
            ISingularity _singularity = ISingularity(data.externalData.singularity);
            IYieldBox _yieldBox = IYieldBox(_singularity._yieldBox());

            uint256 _share =
                _yieldBox.toShare(_singularity._assetId(), data.removeAndRepayData.assetWithdrawData.amount, false);
            // remove asset from SGL
            _singularityRemoveAsset(_singularity, data.removeAndRepayData.removeAmount, data.user, data.user);

            //withdraw
            if (data.removeAndRepayData.assetWithdrawData.withdraw) {
                _yieldBox.transfer(data.user, address(this), _singularity._assetId(), _share);
                _withdrawHere(data.removeAndRepayData.assetWithdrawData);
            }
        }

        /**
         * @dev performs a BigBang repay operation
         */
        if (!data.removeAndRepayData.assetWithdrawData.withdraw && data.removeAndRepayData.repayAssetOnBB) {
            _marketRepay(
                IMarket(data.externalData.bigBang),
                data.externalData.marketHelper,
                data.removeAndRepayData.repayAmount,
                data.user,
                data.user
            );
        }

        /**
         * @dev performs a BigBang removeCollateral operation and withdrawal if requested
         */
        if (data.removeAndRepayData.removeCollateralFromBB) {
            IMarket _bigBang = IMarket(data.externalData.bigBang);
            IYieldBox _yieldBox = IYieldBox(_bigBang._yieldBox());

            // remove collateral
            _marketRemoveCollateral(
                _bigBang,
                data.externalData.marketHelper,
                _yieldBox.toShare(_bigBang._collateralId(), data.removeAndRepayData.collateralAmount, false),
                data.user,
                data.removeAndRepayData.collateralWithdrawData.withdraw ? address(this) : data.user
            );

            //withdraw
            if (data.removeAndRepayData.collateralWithdrawData.withdraw) {
                _withdrawHere(data.removeAndRepayData.collateralWithdrawData);
            }
        }

        /**
         * @dev YieldBox reverts
         */
        _processYieldBoxApprovals(data.externalData.bigBang, data.externalData.singularity, false);
    }

    function _processYieldBoxApprovals(address bigBang, address singularity, bool approve) private {
        if (bigBang == address(0) && singularity == address(0)) return;

        // YieldBox should be the same for all markets
        IYieldBox _yieldBox = bigBang != address(0)
            ? IYieldBox(IMarket(bigBang)._yieldBox())
            : IYieldBox(IMarket(singularity)._yieldBox());

        if (approve) {
            if (bigBang != address(0)) _setApprovalForYieldBox(bigBang, _yieldBox);
            if (singularity != address(0)) _setApprovalForYieldBox(singularity, _yieldBox);
            _setApprovalForYieldBox(address(pearlmit), _yieldBox);
        } else {
            if (bigBang != address(0)) _revertYieldBoxApproval(bigBang, _yieldBox);
            if (singularity != address(0)) _revertYieldBoxApproval(singularity, _yieldBox);
            _revertYieldBoxApproval(address(pearlmit), _yieldBox);
        }
    }

    function _validateLockAndParticipate(LockAndParticipateData memory data) private view {
        // Check sender
        _checkSender(data.user);

        // Check provided addresses
        _checkWhitelisted(data.singularity);
        _checkWhitelisted(data.magnetar);
        if (data.lockData.lock) {
            _checkWhitelisted(data.lockData.target);
        }
        if (data.participateData.participate) {
            _checkWhitelisted(data.participateData.target);
        }
    }

    function _validateExitPositionAndRemoveCollateral(ExitPositionAndRemoveCollateralData memory data) private view {
        // Check sender
        _checkSender(data.user);

        // Check provided addresses
        _checkExternalData(data.externalData);
        _checkRemoveAndRepayData(data.removeAndRepayData);
    }

    function _checkExternalData(ICommonExternalContracts memory data) private view {
        _checkWhitelisted(data.marketHelper);
        _checkWhitelisted(data.magnetar);
        _checkWhitelisted(data.bigBang);
        _checkWhitelisted(data.singularity);
    }

    function _checkRemoveAndRepayData(IRemoveAndRepay memory data) private view {
        _checkWhitelisted(data.exitData.target);
        _checkWhitelisted(data.unlockData.target);

        if (data.exitData.exit) {
            if (data.exitData.oTAPTokenID == 0) revert Magnetar_ActionParamsMismatch();
        }

        if (data.assetWithdrawData.withdraw) {
            // assure unwrap is false because asset is not a TOFT
            if (data.assetWithdrawData.unwrap) revert Magnetar_ComposeMsgNotAllowed();
        }
    }

    function _exit(ExitPositionAndRemoveCollateralData memory data) private returns (uint256 tOLPId) {
        address oTapAddress = ITapiocaOptionBroker(data.removeAndRepayData.exitData.target).oTAP();
        (, ITapiocaOption.TapOption memory oTAPPosition) =
            ITapiocaOption(oTapAddress).attributes(data.removeAndRepayData.exitData.oTAPTokenID);

        tOLPId = oTAPPosition.tOLP;

        // check ownership
        address ownerOfTapTokenId = IERC721(oTapAddress).ownerOf(data.removeAndRepayData.exitData.oTAPTokenID);
        if (ownerOfTapTokenId != data.user && ownerOfTapTokenId != address(this)) {
            revert Magnetar_ActionParamsMismatch();
        }

        // if not owner; get the oTAP token
        if (ownerOfTapTokenId == data.user) {
            bool isErr = pearlmit.transferFromERC721(
                data.user, address(this), oTapAddress, data.removeAndRepayData.exitData.oTAPTokenID
            );
            if (isErr) revert Magnetar_ExtractTokenFail();
        }

        // exit position
        _tOBExit(oTapAddress, data.removeAndRepayData.exitData.target, data.removeAndRepayData.exitData.oTAPTokenID);

        // if not unlock, trasfer tOLP to the user
        if (!data.removeAndRepayData.unlockData.unlock) {
            address tOLPContract = ITapiocaOptionBroker(data.removeAndRepayData.exitData.target).tOLP();

            //transfer tOLP to the data.user
            IERC721(tOLPContract).safeTransferFrom(address(this), data.user, tOLPId, "0x");
        }
    }

    function _unlock(ExitPositionAndRemoveCollateralData memory data, uint256 tOLPId) private {
        if (tOLPId == 0 && data.removeAndRepayData.unlockData.tokenId == 0) revert Magnetar_tOLPTokenMismatch();
        if (
            data.removeAndRepayData.unlockData.tokenId != 0 && tOLPId != 0
                && tOLPId != data.removeAndRepayData.unlockData.tokenId
        ) {
            revert Magnetar_tOLPTokenMismatch();
        }

        if (data.removeAndRepayData.unlockData.tokenId != 0) tOLPId = data.removeAndRepayData.unlockData.tokenId;

        // check ownership
        address ownerOfTOLP = IERC721(data.removeAndRepayData.unlockData.target).ownerOf(tOLPId);
        if (ownerOfTOLP != data.user && ownerOfTOLP != address(this)) revert Magnetar_ActionParamsMismatch();

        (uint128 sglAssetId, uint128 ybShares,,) =
            ITapiocaOptionLiquidityProvision(data.removeAndRepayData.unlockData.target).lockPositions(tOLPId);

        // will be sent to `data.user` or `address(this)`
        ITapiocaOptionLiquidityProvision(data.removeAndRepayData.unlockData.target).unlock(
            tOLPId, data.externalData.singularity
        );

        // in case owner is `address(this)`
        //    transfer unlocked position to the user
        if (ownerOfTOLP == address(this)) {
            IYieldBox _yieldBox =
                IYieldBox(ITapiocaOptionLiquidityProvision(data.removeAndRepayData.unlockData.target).yieldBox());
            _yieldBox.transfer(address(this), data.user, sglAssetId, ybShares);
        }
    }
}
