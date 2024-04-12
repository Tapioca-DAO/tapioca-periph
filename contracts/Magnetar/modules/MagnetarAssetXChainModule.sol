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

import {MagnetarAssetCommonModule} from "./MagnetarAssetCommonModule.sol";

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
contract MagnetarAssetXChainModule is MagnetarAssetCommonModule {
    using SafeERC20 for IERC20;
    using SafeApprove for address;

    error Magnetar_UserMismatch();

    /// =====================
    /// Public
    /// =====================

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
        uint256 toftAmount = _wrapSglReceipt(IYieldBox(yieldBox), data.singularity, data.user, fraction, data.assetId, true, address(this));

        data.lockAndParticipateSendParams.lzParams.sendParam.amountLD = toftAmount;

        // decode `composeMsg` and re-encode it with updated params
        (uint16 msgType_,, uint16 msgIndex_, bytes memory tapComposeMsg_, bytes memory nextMsg_) =
        TapiocaOmnichainEngineCodec.decodeToeComposeMsg(data.lockAndParticipateSendParams.lzParams.sendParam.composeMsg);

        LockAndParticipateData memory lockData = abi.decode(tapComposeMsg_, (LockAndParticipateData));
        if (lockData.user != data.user) revert Magnetar_UserMismatch();

        lockData.fraction = toftAmount;

        data.lockAndParticipateSendParams.lzParams.sendParam.composeMsg =
            TapiocaOmnichainEngineCodec.encodeToeComposeMsg(abi.encode(lockData), msgType_, msgIndex_, nextMsg_);

        // send on another layer for lending
        _withdrawToChain(
            MagnetarWithdrawData({
                yieldBox: yieldBox,
                assetId: data.assetId,
                unwrap: true, //doesn't unwrap but calls it with `composeMsg`
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
}
