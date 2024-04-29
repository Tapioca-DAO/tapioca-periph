// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Tapioca
import {
    MintFromBBAndLendOnSGLData,
    CrossChainMintFromBBAndLendOnSGLData,
    DepositAndSendForLockingData,
    LockAndParticipateData,
    MagnetarWithdrawData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {TapiocaOmnichainEngineCodec} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainEngineCodec.sol";
import {MagnetarBaseModuleExternal} from "./MagnetarBaseModuleExternal.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IMarket, Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {MagnetarMintCommonModule} from "./MagnetarMintCommonModule.sol";
import {ITOFT} from "tapioca-periph/interfaces/oft/ITOFT.sol";
/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title MagnetarMintXChainModule
 * @author TapiocaDAO
 * @notice Magnetar cross chain BigBang related operations
 */
contract MagnetarMintXChainModule is MagnetarMintCommonModule {
    using SafeERC20 for IERC20;

    error Magnetar_UserMismatch();

    constructor(address _magnetarBaseModuleExternal) MagnetarMintCommonModule(_magnetarBaseModuleExternal) {}

    /// =====================
    /// Public
    /// =====================
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
        _validateMintBBLendXChainSGL(data);

        address yieldBox = IMarket(data.bigBang)._yieldBox();

        // if `mint` was requested the following actions are performed:
        //  - extracts & deposits collateral to YB
        //  - performs bigBang_.addCollateral
        //  - performs bigBang_.borrow
        if (data.mintData.mint) {
            _depositYBBorrowBB(data.mintData, data.bigBang, IYieldBox(yieldBox), data.user, data.marketHelper);
        }

        {
            // decode `composeMsg` and re-encode it with updated params
            (uint16 msgType_,, uint16 msgIndex_, bytes memory tapComposeMsg_, bytes memory nextMsg_) =
                TapiocaOmnichainEngineCodec.decodeToeComposeMsg(data.lendSendParams.lzParams.sendParam.composeMsg);

            // assert composeMsg format & user
            DepositAndSendForLockingData memory lendData = abi.decode(tapComposeMsg_, (DepositAndSendForLockingData));
            if (lendData.user != data.user) revert Magnetar_UserMismatch();

            // if omitted by user, make sure to overwrite it with the deposited amount
            if (data.mintData.mint && lendData.lendAmount == 0) {
                lendData.lendAmount = data.mintData.mintAmount;
                data.lendSendParams.lzParams.sendParam.amountLD = data.mintData.mintAmount;
                data.lendSendParams.lzParams.sendParam.minAmountLD =
                    ITOFT(IMarket(data.bigBang)._asset()).removeDust(data.mintData.mintAmount);
            }

            data.lendSendParams.lzParams.sendParam.composeMsg =
                TapiocaOmnichainEngineCodec.encodeToeComposeMsg(abi.encode(lendData), msgType_, msgIndex_, nextMsg_);
        }

        {
            IYieldBox(yieldBox).transfer(
                data.user,
                address(this),
                IMarket(data.bigBang)._assetId(),
                data.lendSendParams.lzParams.sendParam.amountLD
            );
            // send on another layer for lending
            // already validated above
            _executeDelegateCall(
                magnetarBaseModuleExternal,
                abi.encodeWithSelector(
                    MagnetarBaseModuleExternal.withdrawToChain.selector,
                    MagnetarWithdrawData({
                        yieldBox: yieldBox,
                        assetId: IMarket(data.bigBang)._assetId(),
                        compose: true,
                        lzSendParams: data.lendSendParams.lzParams,
                        sendGas: data.lendSendParams.lzSendGas,
                        composeGas: data.lendSendParams.lzComposeGas,
                        sendVal: data.lendSendParams.lzSendVal,
                        composeVal: data.lendSendParams.lzComposeVal,
                        composeMsgType: data.lendSendParams.lzComposeMsgType,
                        withdraw: true
                    })
                )
            );
        }
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
        // if `lockData.lock`:
        //      - transfer `fraction` from data.user to `address(this)
        //      - deposits `fraction` to YB for `address(this)`
        //      - performs tOLP.lock
        uint256 tOLPTokenId = _lockOnTOB(
            data.lockData,
            IYieldBox(IMarket(data.singularity)._yieldBox()),
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
            _participateOnTOLP(data.participateData, data.user, data.lockData.target, tOLPTokenId, data.lockData.lock);
        }
    }

    function _validateMintBBLendXChainSGL(CrossChainMintFromBBAndLendOnSGLData memory data) private view {
        // Check sender
        _checkSender(data.user);

        // Check provided addresses
        _checkWhitelisted(data.bigBang);
        _checkWhitelisted(data.magnetar);
        _checkWhitelisted(data.marketHelper);

        // Check lend data
        IMarket marketBB = IMarket(data.bigBang);
        (, address asset,,) = IYieldBox(marketBB._yieldBox()).assets(marketBB._assetId());
        _checkWhitelisted(asset);
    }
}
