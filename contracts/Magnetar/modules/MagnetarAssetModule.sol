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
        if (!cluster.isWhitelisted(0, address(data.marketHelper))) {
            revert Magnetar_TargetNotWhitelisted(address(data.marketHelper));
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
            (Module[] memory modules, bytes[] memory calls) = IMarketHelper(data.marketHelper).repay(
                data.depositAmount > 0 ? address(this) : data.user, data.user, false, data.repayAmount
            );
            _market.execute(modules, calls, true);
            _revertYieldBoxApproval(data.market, _yieldBox);
        }

        /**
         * @dev performs a remove collateral market operation;
         *       also withdraws if requested.
         */
        if (data.collateralAmount > 0) {
            address collateralWithdrawReceiver = data.withdrawCollateralParams.withdraw ? address(this) : data.user;
            uint256 collateralShare = _yieldBox.toShare(_market.collateralId(), data.collateralAmount, false);

            (Module[] memory modules, bytes[] memory calls) = IMarketHelper(data.marketHelper).removeCollateral(
                data.user, collateralWithdrawReceiver, collateralShare
            );
            _market.execute(modules, calls, true);

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
        (uint16 msgType_,, uint16 msgIndex_, bytes memory tapComposeMsg_, bytes memory nextMsg_) =
            TapiocaOmnichainEngineCodec.decodeToeComposeMsg(data.lockAndParticipateSendParams.lzParams.sendParam.composeMsg);

        LockAndParticipateData memory lockData = abi.decode(tapComposeMsg_, (LockAndParticipateData));
        lockData.fraction = toftAmount;

        data.lockAndParticipateSendParams.lzParams.sendParam.composeMsg = TapiocaOmnichainEngineCodec.encodeToeComposeMsg(abi.encode(lockData), msgType_, msgIndex_, nextMsg_);

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


    function _wrapSglReceipt(IYieldBox yieldBox, address sgl, address user, uint256 fraction, uint256 assetId)
        private
        returns (uint256 toftAmount)
    {
        IERC20(sgl).safeTransferFrom(user, address(this), fraction);

        (, address tReceiptAddress,,) = yieldBox.assets(assetId);

        IERC20(sgl).approve(tReceiptAddress, fraction);
        toftAmount = ITOFT(tReceiptAddress).wrap(address(this), address(this), fraction);
        IERC20(tReceiptAddress).safeTransfer(user, toftAmount);
    }
    function _depositYBLendSGL(
        IDepositData memory depositData,
        address singularityAddress,
        IYieldBox yieldBox_,
        address user,
        uint256 lendAmount
    ) private returns (uint256 fraction) {
        if (singularityAddress != address(0)) {
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


}
