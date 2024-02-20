// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Tapioca
import {
    MintFromBBAndLendOnSGLData,
    CrossChainMintFromBBAndLendOnSGLData,
    IMintData,
    IDepositData,
    IOptionsLockData,
    IOptionsParticipateData,
    DepositAndSendForLockingData,
    LockAndParticipateData,
    MagnetarWithdrawData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {TapiocaOmnichainEngineCodec} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainEngineCodec.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {IMarketHelper} from "tapioca-periph/interfaces/bar/IMarketHelper.sol";
import {MagnetarMintExternalHelper} from "./MagnetarMintExternalHelper.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IMarket, Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
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
 * @title MagnetarMintModule
 * @author TapiocaDAO
 * @notice Magnetar BigBang related operations
 */
contract MagnetarMintModule is MagnetarBaseModule {
    using SafeApprove for address;
    using SafeERC20 for IERC20;

    error Magnetar_ActionParamsMismatch();
    error Magnetar_tOLPTokenMismatch();

    event Magnetar_ZeroAddress();

    MagnetarMintExternalHelper private _externalHelper;

    constructor() {
        _externalHelper = new MagnetarMintExternalHelper();
    }

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
        // Check sender
        _checkSender(data.user);

        IYieldBox yieldBox_ = IYieldBox(IMarket(data.externalContracts.singularity).yieldBox());

        // if `mint` was requested the following actions are performed:
        //  - extracts & deposits collateral to YB
        //  - performs bigBang_.addCollateral
        //  - performs bigBang_.borrow
        if (data.mintData.mint) {
            _depositYBBorrowBB(
                data.mintData, data.externalContracts.bigBang, yieldBox_, data.user, data.externalContracts.marketHelper
            );
        }

        // if `depositData.deposit`:
        //      - deposit SGL asset to YB for `data.user`
        // if `lendAmount` > 0:
        //      - add asset to SGL
        uint256 fraction = _depositYBLendSGL(
            data.depositData, data.externalContracts.singularity, yieldBox_, data.user, data.lendAmount
        );

        // if `lockData.lock`:
        //      - transfer `fraction` from data.user to `address(this)
        //      - deposits `fraction` to YB for `address(this)`
        //      - performs tOLP.lock
        uint256 tOLPTokenId = _lockOnTOB(
            data.lockData,
            yieldBox_,
            fraction,
            data.participateData.participate,
            data.user,
            data.externalContracts.singularity
        );

        // if `participateData.participate`:
        //      - verify tOLPTokenId
        //      - performs tOB.participate
        //      - transfer `oTAPTokenId` to data.user
        if (data.participateData.participate) {
            _participateOnTOLP(data.participateData, data.user, data.lockData.target, tOLPTokenId);
        }
    }

    /**
     * @notice cross-chain helper to deposit mint from BB, lend on SGL, lock on tOLP and participate on tOB
     * @dev Cross chain flow:
     *  step 1: magnetar.mintBBLendXChainSGL (chain A) -->
     *         step 2: IUsdo compose call calls magnetar.depositYBLendSGLLockXchainTOLP (chain B) -->
     *              step 3: IToft(sglReceipt) compose call calls magnetar.lockAndParticipate (chain X)
     *  Mints from BB and sends borrowed Usdo to another layer for lending
     *  ! Handles `step 1` described above !
     *  !!! All uint variables should be in the LD format !!!
     *  !!! Sets `lendAmount` parameter of the next call (step 2) !!!
     * @param data.user the user to perform the operation for
     * @param data.bigBang the BB address
     * @param data.mintData the data needed to mint on BB
     * @param data.lendSendParams LZ send params for lending on another layer
     */
    function mintBBLendXChainSGL(CrossChainMintFromBBAndLendOnSGLData memory data) public payable {
        // Check sender
        _checkSender(data.user);

        address yieldBox = IMarket(data.bigBang).yieldBox();

        // if `mint` was requested the following actions are performed:
        //  - extracts & deposits collateral to YB
        //  - performs bigBang_.addCollateral
        //  - performs bigBang_.borrow
        if (data.mintData.mint) {
            _depositYBBorrowBB(data.mintData, data.bigBang, IYieldBox(yieldBox), data.user, data.marketHelper);
        }

        // decode `composeMsg` and re-encode it with updated params
        data.lendSendParams.lzParams.sendParam.composeMsg = _externalHelper.mintBBLendXChainSGLEncoder(
            data.lendSendParams.lzParams.sendParam.composeMsg, data.mintData.mintAmount
        );

        // send on another layer for lending
        _withdrawToChain(
            MagnetarWithdrawData({
                yieldBox: yieldBox,
                assetId: IMarket(data.bigBang).assetId(),
                unwrap: false,
                lzSendParams: data.lendSendParams.lzParams,
                sendGas: data.lendSendParams.lzSendGas,
                composeGas: data.lendSendParams.lzComposeGas,
                sendVal: data.lendSendParams.lzSendVal,
                composeVal: data.lendSendParams.lzComposeVal,
                composeMsg: data.lendSendParams.lzParams.sendParam.composeMsg,
                composeMsgType: data.lendSendParams.lzComposeMsgType,
                withdraw: true
            })
        );
    }

    /**
     * @notice cross-chain helper to deposit mint from BB, lend on SGL, lock on tOLP and participate on tOB
     * @dev Cross chain flow:
     *  step 1: magnetar.mintBBLendXChainSGL (chain A) -->
     *         step 2: IUsdo compose call calls magnetar.depositYBLendSGLLockXchainTOLP (chain B) -->
     *              step 3: IToft(sglReceipt) compose call calls magnetar.lockAndParticipate (chain X)
     *  Lends on SGL and sends receipt token on another layer
     *  ! Handles `step 2` described above !
     *  !!! All uint variables should be in the LD format !!!
     *  !!! Sets `fraction` parameter of the next call (step 2) !!!
     * @param data.user the user to perform the operation for
     * @param data.singularity the SGL address
     * @param data.lendAmount the amount to lend on SGL
     * @param data.depositData the data needed to deposit on YieldBox
     * @param data.lockAndParticipateSendParams LZ send params for the lock or/and the participate operations
     */
    function depositYBLendSGLLockXchainTOLP(DepositAndSendForLockingData memory data) public payable {
        // Check sender
        _checkSender(data.user);

        address yieldBox = IMarket(data.singularity).yieldBox();

        // if `depositData.deposit`:
        //      - deposit SGL asset to YB for `data.user`
        // if `lendAmount` > 0:
        //      - add asset to SGL
        uint256 fraction =
            _depositYBLendSGL(data.depositData, data.singularity, IYieldBox(yieldBox), data.user, data.lendAmount);

        // wrap SGL receipt into tReceipt
        // ! User should approve `address(this)` for `IERC20(data.singularity)` !
        uint256 toftAmount = _wrapSglReceipt(IYieldBox(yieldBox), data.singularity, data.user, fraction, data.assetId);

        data.lockAndParticipateSendParams.lzParams.sendParam.amountLD = toftAmount;

        // decode `composeMsg` and re-encode it with updated params
        data.lockAndParticipateSendParams.lzParams.sendParam.composeMsg = _externalHelper
            .depositYBLendSGLLockXchainTOLPEncoder(
            data.lockAndParticipateSendParams.lzParams.sendParam.composeMsg, toftAmount
        );

        // send on another layer for lending
        _withdrawToChain(
            MagnetarWithdrawData({
                yieldBox: yieldBox,
                assetId: data.assetId,
                unwrap: false,
                lzSendParams: data.lockAndParticipateSendParams.lzParams,
                sendGas: data.lockAndParticipateSendParams.lzSendGas,
                composeGas: data.lockAndParticipateSendParams.lzComposeGas,
                sendVal: data.lockAndParticipateSendParams.lzSendVal,
                composeVal: data.lockAndParticipateSendParams.lzComposeVal,
                composeMsg: data.lockAndParticipateSendParams.lzParams.sendParam.composeMsg,
                composeMsgType: data.lockAndParticipateSendParams.lzComposeMsgType,
                withdraw: true
            })
        );
    }

    /**
     * @notice cross-chain helper to deposit mint from BB, lend on SGL, lock on tOLP and participate on tOB
     * @dev Cross chain flow:
     *  step 1: magnetar.mintBBLendXChainSGL (chain A) -->
     *         step 2: IUsdo compose call calls magnetar.depositYBLendSGLLockXchainTOLP (chain B) -->
     *              step 3: IToft(sglReceipt) compose call calls magnetar.lockAndParticipate (chain X)
     *  Lock on tOB and/or participate on tOLP
     *  ! Handles `step 3` described above !
     *  !!! All uint variables should be in the LD format !!!
     * @param data.user the user to perform the operation for
     * @param data.singularity the SGL address
     * @param data.fraction the amount to lock
     * @param data.lockData the data needed to lock on tOB
     * @param data.participateData the data needed to participate on tOLP
     */
    function lockAndParticipate(LockAndParticipateData memory data) public payable {
        // Check sender
        _checkSender(data.user);

        // if `lockData.lock`:
        //      - transfer `fraction` from data.user to `address(this)
        //      - deposits `fraction` to YB for `address(this)`
        //      - performs tOLP.lock
        uint256 tOLPTokenId = _lockOnTOB(
            data.lockData,
            IYieldBox(IMarket(data.singularity).yieldBox()),
            data.fraction,
            data.participateData.participate,
            data.user,
            data.singularity
        );

        // if `participateData.participate`:
        //      - verify tOLPTokenId
        //      - performs tOB.participate
        //      - transfer `oTAPTokenId` to data.user
        if (data.participateData.participate) {
            _participateOnTOLP(data.participateData, data.user, data.lockData.target, tOLPTokenId);
        }
    }

    /// =====================
    /// Private
    /// =====================
    function _wrapSglReceipt(IYieldBox yieldBox, address sgl, address user, uint256 fraction, uint256 assetId)
        private
        returns (uint256 toftAmount)
    {
        // IERC20(sgl).safeTransferFrom(user, address(this), fraction);
        pearlmit.transferFromERC20(user, address(this), sgl, fraction);

        (, address tReceiptAddress,,) = yieldBox.assets(assetId);

        IERC20(sgl).approve(tReceiptAddress, fraction);
        toftAmount = ITOFT(tReceiptAddress).wrap(address(this), address(this), fraction);
        IERC20(tReceiptAddress).safeTransfer(user, toftAmount);
    }

    function _participateOnTOLP(
        IOptionsParticipateData memory participateData,
        address user,
        address lockDataTarget,
        uint256 tOLPTokenId
    ) private {
        if (!cluster.isWhitelisted(0, participateData.target)) {
            revert Magnetar_TargetNotWhitelisted(participateData.target);
        }

        // Check tOLPTokenId
        if (participateData.tOLPTokenId != 0) {
            if (participateData.tOLPTokenId != tOLPTokenId && tOLPTokenId != 0) {
                revert Magnetar_tOLPTokenMismatch();
            }

            tOLPTokenId = participateData.tOLPTokenId;
        }
        if (tOLPTokenId == 0) revert Magnetar_ActionParamsMismatch();

        IERC721(lockDataTarget).approve(participateData.target, tOLPTokenId);
        uint256 oTAPTokenId = ITapiocaOptionBroker(participateData.target).participate(tOLPTokenId);

        address oTapAddress = ITapiocaOptionBroker(participateData.target).oTAP();
        IERC721(oTapAddress).safeTransferFrom(address(this), user, oTAPTokenId, "0x");
    }

    function _lockOnTOB(
        IOptionsLockData memory lockData,
        IYieldBox yieldBox_,
        uint256 fraction,
        bool participate,
        address user,
        address singularityAddress
    ) private returns (uint256 tOLPTokenId) {
        tOLPTokenId = 0;
        if (lockData.lock) {
            if (!cluster.isWhitelisted(0, lockData.target)) {
                revert Magnetar_TargetNotWhitelisted(lockData.target);
            }
            if (lockData.fraction > 0) fraction = lockData.fraction;

            // retrieve and deposit SGLAssetId registered in tOLP
            (uint256 tOLPSglAssetId,,) =
                ITapiocaOptionLiquidityProvision(lockData.target).activeSingularities(singularityAddress);
            if (fraction == 0) revert Magnetar_ActionParamsMismatch();

            //deposit to YieldBox
            // IERC20(singularityAddress).safeTransferFrom(user, address(this), fraction);
            pearlmit.transferFromERC20(user, address(this), singularityAddress, fraction);
            singularityAddress.safeApprove(address(yieldBox_), fraction);
            yieldBox_.depositAsset(tOLPSglAssetId, address(this), address(this), fraction, 0);

            _setApprovalForYieldBox(lockData.target, yieldBox_);
            tOLPTokenId = ITapiocaOptionLiquidityProvision(lockData.target).lock(
                participate ? address(this) : user, singularityAddress, lockData.lockDuration, lockData.amount
            );
            _revertYieldBoxApproval(lockData.target, yieldBox_);
        }
    }

    function _depositYBLendSGL(
        IDepositData memory depositData,
        address singularityAddress,
        IYieldBox yieldBox_,
        address user,
        uint256 lendAmount
    ) private returns (uint256 fraction) {
        if (singularityAddress == address(0)) {
            // @dev for dev trace
            emit Magnetar_ZeroAddress();
        } else {
            if (!cluster.isWhitelisted(0, singularityAddress)) {
                revert Magnetar_TargetNotWhitelisted(singularityAddress);
            }
            _setApprovalForYieldBox(singularityAddress, yieldBox_);

            IMarket singularity_ = IMarket(singularityAddress);

            // if `depositData.deposit`:
            //      - deposit SGL asset to YB for `user`
            uint256 sglAssetId = singularity_.assetId();
            (, address sglAssetAddress,,) = yieldBox_.assets(sglAssetId);
            if (depositData.deposit) {
                depositData.amount = _extractTokens(user, sglAssetAddress, depositData.amount);

                sglAssetAddress.safeApprove(address(yieldBox_), depositData.amount);
                yieldBox_.depositAsset(sglAssetId, address(this), user, depositData.amount, 0);
            }

            // if `lendAmount` > 0:
            //      - add asset to SGL
            fraction = 0;
            if (lendAmount == 0 && depositData.deposit) {
                lendAmount = depositData.amount;
            }
            if (lendAmount > 0) {
                uint256 lendShare = yieldBox_.toShare(sglAssetId, lendAmount, false);
                fraction = ISingularity(singularityAddress).addAsset(user, user, false, lendShare);
            }

            _revertYieldBoxApproval(singularityAddress, yieldBox_);
        }
    }

    function _depositYBBorrowBB(
        IMintData memory mintData,
        address bigBangAddress,
        IYieldBox yieldBox_,
        address user,
        address marketHelper
    ) private {
        if (bigBangAddress == address(0)) {
            // @dev for dev trace
            emit Magnetar_ZeroAddress();
        } else {
            if (!cluster.isWhitelisted(0, bigBangAddress)) {
                revert Magnetar_TargetNotWhitelisted(bigBangAddress);
            }

            if (!cluster.isWhitelisted(0, marketHelper)) {
                revert Magnetar_TargetNotWhitelisted(marketHelper);
            }

            _setApprovalForYieldBox(bigBangAddress, yieldBox_);

            IMarket bigBang_ = IMarket(bigBangAddress);

            // retrieve collateral id & address
            uint256 bbCollateralId = bigBang_.collateralId();
            (, address bbCollateralAddress,,) = yieldBox_.assets(bbCollateralId);

            // compute collateral share
            uint256 bbCollateralShare = yieldBox_.toShare(bbCollateralId, mintData.collateralDepositData.amount, false);

            // deposit collateral to YB
            if (mintData.collateralDepositData.deposit) {
                mintData.collateralDepositData.amount =
                    _extractTokens(user, bbCollateralAddress, mintData.collateralDepositData.amount);
                bbCollateralShare = yieldBox_.toShare(bbCollateralId, mintData.collateralDepositData.amount, false);

                bbCollateralAddress.safeApprove(address(yieldBox_), mintData.collateralDepositData.amount);
                yieldBox_.depositAsset(
                    bbCollateralId, address(this), address(this), mintData.collateralDepositData.amount, 0
                );
            }

            // add collateral to BB
            if (mintData.collateralDepositData.amount > 0) {
                _setApprovalForYieldBox(address(bigBang_), yieldBox_);

                (Module[] memory modules, bytes[] memory calls) = IMarketHelper(marketHelper).addCollateral(
                    mintData.collateralDepositData.deposit ? address(this) : user,
                    user,
                    false,
                    mintData.collateralDepositData.amount,
                    bbCollateralShare
                );
                bigBang_.execute(modules, calls, true);
            }

            // mints from BB
            {
                (Module[] memory modules, bytes[] memory calls) =
                    IMarketHelper(marketHelper).borrow(user, user, mintData.mintAmount);
                bigBang_.execute(modules, calls, true);
            }

            _revertYieldBoxApproval(bigBangAddress, yieldBox_);
        }
    }
}
