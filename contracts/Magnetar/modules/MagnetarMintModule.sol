// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {MintFromBBAndLendOnSGLData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
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
    using SafeCast for uint256;

    constructor(IPearlmit pearlmit, address _toeHelper) MagnetarBaseModule(pearlmit, _toeHelper) {}
    /// =====================
    /// Public
    /// =====================
    /**
     * @notice helper to deposit mint from BB, lend on SGL, lock on tOLP and participate on tOB on the current chain
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
    function mintBBLendSGLLockTOLP(MintFromBBAndLendOnSGLData memory data) public payable {
        /**
         * @dev validate data
         */
        _validatemintBBLendSGLLockTOLPData(data);

        /**
         * @dev YieldBox approvals
         */
        _processYieldBoxApprovals(
            data.externalContracts.bigBang, data.externalContracts.singularity, data.lockData.target, true
        );

        /**
         * @dev if `mint` was requested the following actions are performed:
         *      - extracts & deposits collateral to YB
         *      - performs bigBang_.addCollateral
         *      - performs bigBang_.borrow
         */
        if (data.mintData.mint && data.externalContracts.bigBang != address(0)) {
            _depositAddCollateralAndMintFromBigBang(data);
        }

        /**
         * @dev if `depositData.deposit`:
         *          - deposit SGL asset to YB for `data.user`
         *      Note: if mint (first step), assets are already in YieldBox
         */
        if (data.depositData.deposit) {
            IMarket _singularity = IMarket(data.externalContracts.singularity);
            IYieldBox _yieldBox = IYieldBox(_singularity._yieldBox());

            uint256 sglAssetId = _singularity._assetId();
            (, address sglAssetAddress,,) = _yieldBox.assets(sglAssetId);

            data.depositData.amount = _extractTokens(data.user, sglAssetAddress, data.depositData.amount);
            _depositToYb(_yieldBox, data.user, sglAssetId, data.depositData.amount);
        }

        /**
         * @dev if `lendAmount` > 0:
         *          - add asset to SGL
         */
        uint256 fraction;
        if (data.lendAmount > 0) {
            fraction = _singularityAddAsset(
                ISingularity(data.externalContracts.singularity), data.lendAmount, data.user, data.user
            );
        }

        /**
         * @dev if `lockData.lock`:
         *          - transfer `fraction` from data.user to `address(this)
         *          - deposits `fraction` to YB for `address(this)`
         *          - performs tOLP.lock
         */
        uint256 tOLPTokenId;
        if (data.lockData.lock) {
            tOLPTokenId = _lock(data, fraction);
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

        /**
         * @dev YieldBox reverts
         */
        _processYieldBoxApprovals(
            data.externalContracts.bigBang, data.externalContracts.singularity, data.lockData.target, false
        );
    }

    /// =====================
    /// Private
    /// =====================
    function _processYieldBoxApprovals(address bigBang, address singularity, address lockTarget, bool approve)
        private
    {
        if (bigBang == address(0) && singularity == address(0)) return;

        // YieldBox should be the same for all markets
        IYieldBox _yieldBox = bigBang != address(0)
            ? IYieldBox(IMarket(bigBang)._yieldBox())
            : IYieldBox(IMarket(singularity)._yieldBox());

        if (approve) {
            if (bigBang != address(0)) _setApprovalForYieldBox(bigBang, _yieldBox);
            if (singularity != address(0)) _setApprovalForYieldBox(singularity, _yieldBox);
            if (lockTarget != address(0)) _setApprovalForYieldBox(lockTarget, _yieldBox);
            _setApprovalForYieldBox(address(pearlmit), _yieldBox);
        } else {
            if (bigBang != address(0)) _revertYieldBoxApproval(bigBang, _yieldBox);
            if (singularity != address(0)) _revertYieldBoxApproval(singularity, _yieldBox);
            if (lockTarget != address(0)) _revertYieldBoxApproval(lockTarget, _yieldBox);
            _revertYieldBoxApproval(address(pearlmit), _yieldBox);
        }
    }

    function _validatemintBBLendSGLLockTOLPData(MintFromBBAndLendOnSGLData memory data) private view {
        // Check sender
        _checkSender(data.user);

        // Check provided addresses
        _checkWhitelisted(data.externalContracts.magnetar);
        _checkWhitelisted(data.externalContracts.singularity);
        _checkWhitelisted(data.externalContracts.bigBang);
        _checkWhitelisted(data.externalContracts.marketHelper);
        _checkWhitelisted(data.lockData.target);
        _checkWhitelisted(data.participateData.target);
    }

    function _depositAddCollateralAndMintFromBigBang(MintFromBBAndLendOnSGLData memory data) private {
        IMarket _bigBang = IMarket(data.externalContracts.bigBang);
        IYieldBox _yieldBox = IYieldBox(_bigBang._yieldBox());

        uint256 bbCollateralId = _bigBang._collateralId();
        uint256 _share;

        /**
         * @dev try deposit to YieldBox
         */
        if (data.mintData.collateralDepositData.deposit) {
            (, address bbCollateralAddress,,) = _yieldBox.assets(bbCollateralId);

            data.mintData.collateralDepositData.amount =
                _extractTokens(data.user, bbCollateralAddress, data.mintData.collateralDepositData.amount);
            _share = _yieldBox.toShare(bbCollateralId, data.mintData.collateralDepositData.amount, false);

            _depositToYb(_yieldBox, data.user, bbCollateralId, data.mintData.collateralDepositData.amount);
        }

        /**
         * @dev try to add collateral
         *      `data.mintData.collateralDepositData.deposit` might be false and YieldBox deposit is skipped, but
         *          `data.mintData.collateralDepositData.amount` can be > 0, which assumes that an `.addCollateral` operation is performed
         */
        if (data.mintData.collateralDepositData.amount > 0) {
            _marketAddCollateral(_bigBang, data.externalContracts.marketHelper, _share, data.user, data.user);
        }

        /**
         * @dev try borrow from BigBang
         */
        if (data.mintData.mintAmount > 0) {
            uint256 _assetId = _bigBang._assetId();
            _share = _yieldBox.toShare(_assetId, data.mintData.mintAmount, false);

            _pearlmitApprove(address(_yieldBox), _assetId, address(_bigBang), _share);
            _marketBorrow(_bigBang, data.externalContracts.marketHelper, data.mintData.mintAmount, data.user, data.user);
        }
    }

    function _lock(MintFromBBAndLendOnSGLData memory data, uint256 fraction) private returns (uint256 tOLPTokenId) {
        IMarket _singularity = IMarket(data.externalContracts.singularity);
        IYieldBox _yieldBox = IYieldBox(_singularity._yieldBox());

        // use requested value
        if (data.lockData.fraction > 0) {
            fraction = data.lockData.fraction;
        }
        if (fraction == 0) revert Magnetar_ActionParamsMismatch();

        // retrieve and deposit SGLAssetId registered in tOLP
        (uint256 tOLPSglAssetId,,) = ITapiocaOptionLiquidityProvision(data.lockData.target).activeSingularities(
            data.externalContracts.singularity
        );

        fraction = _extractTokens(data.user, data.externalContracts.singularity, fraction);
        _depositToYb(_yieldBox, data.user, tOLPSglAssetId, fraction);

        tOLPTokenId = ITapiocaOptionLiquidityProvision(data.lockData.target).lock(
            data.user, data.externalContracts.singularity, data.lockData.lockDuration, data.lockData.amount
        );
    }

    function _participate(MintFromBBAndLendOnSGLData memory data, uint256 tOLPTokenId) private {
        // validate token ids
        if (tOLPTokenId == 0 && data.participateData.tOLPTokenId == 0) revert Magnetar_ActionParamsMismatch();
        if (
            data.participateData.tOLPTokenId != tOLPTokenId && tOLPTokenId != 0 && data.participateData.tOLPTokenId != 0
        ) {
            revert Magnetar_tOLPTokenMismatch();
        }

        if (data.participateData.tOLPTokenId != 0) tOLPTokenId = data.participateData.tOLPTokenId;

        // transfer NFT here
        bool isErr = pearlmit.transferFromERC721(data.user, address(this), data.lockData.target, tOLPTokenId);
        if (isErr) revert Magnetar_ExtractTokenFail();

        pearlmit.approve(data.lockData.target, tOLPTokenId, data.participateData.target, 1, (block.timestamp + 1).toUint48());
        IERC721(data.lockData.target).approve(address(pearlmit), tOLPTokenId);
        uint256 oTAPTokenId = ITapiocaOptionBroker(data.participateData.target).participate(tOLPTokenId);

        address oTapAddress = ITapiocaOptionBroker(data.participateData.target).oTAP();
        IERC721(oTapAddress).safeTransferFrom(address(this), data.user, oTAPTokenId, "");
    }
}
