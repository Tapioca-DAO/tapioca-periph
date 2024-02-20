// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {MintFromBBAndLendOnSGLData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {MagnetarMintCommonModule} from "./MagnetarMintCommonModule.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";

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
contract MagnetarMintModule is MagnetarMintCommonModule {
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
}
