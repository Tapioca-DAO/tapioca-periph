// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ExitPositionAndRemoveCollateralData, MagnetarWithdrawData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOption} from "tapioca-periph/interfaces/tap-token/ITapiocaOption.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {MagnetarBaseModule} from "./MagnetarBaseModule.sol";
/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/**
 * @title MagnetarOptionModule
 * @author TapiocaDAO
 * @notice Magnetar options related operations
 */
contract MagnetarOptionModule is MagnetarBaseModule {
    using SafeERC20 for IERC20;

    error Magnetar_ActionParamsMismatch();
    error Magnetar_tOLPTokenMismatch();

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
        // Check sender
        _checkSender(data.user);

        // Check whitelisted
        if (data.externalData.bigBang != address(0)) {
            if (!cluster.isWhitelisted(0, data.externalData.bigBang)) {
                revert Magnetar_TargetNotWhitelisted(data.externalData.bigBang);
            }
        }
        if (data.externalData.singularity != address(0)) {
            if (!cluster.isWhitelisted(0, data.externalData.singularity)) {
                revert Magnetar_TargetNotWhitelisted(data.externalData.singularity);
            }
        }

        IMarket bigBang_ = IMarket(data.externalData.bigBang);
        ISingularity singularity_ = ISingularity(data.externalData.singularity);
        IYieldBox yieldBox_ = IYieldBox(singularity_.yieldBox());

        // if `removeAndRepayData.exitData.exit` the following operations are performed
        //      - if ownerOfTapTokenId is user, transfers the oTAP token id to this contract
        //      - tOB.exitPosition
        //      - if `!removeAndRepayData.unlockData.unlock`, transfer the obtained tokenId to the user
        uint256 tOLPId = 0;
        if (data.removeAndRepayData.exitData.exit) {
            if (data.removeAndRepayData.exitData.oTAPTokenID == 0) revert Magnetar_ActionParamsMismatch();
            if (!cluster.isWhitelisted(0, data.removeAndRepayData.exitData.target)) {
                revert Magnetar_TargetNotWhitelisted(data.removeAndRepayData.exitData.target);
            }

            address oTapAddress = ITapiocaOptionBroker(data.removeAndRepayData.exitData.target).oTAP();
            (, ITapiocaOption.TapOption memory oTAPPosition) =
                ITapiocaOption(oTapAddress).attributes(data.removeAndRepayData.exitData.oTAPTokenID);

            tOLPId = oTAPPosition.tOLP;

            address ownerOfTapTokenId = IERC721(oTapAddress).ownerOf(data.removeAndRepayData.exitData.oTAPTokenID);

            if (ownerOfTapTokenId != data.user && ownerOfTapTokenId != address(this)) {
                revert Magnetar_ActionParamsMismatch();
            }
            if (ownerOfTapTokenId == data.user) {
                IERC721(oTapAddress).safeTransferFrom(
                    data.user, address(this), data.removeAndRepayData.exitData.oTAPTokenID, "0x"
                );
            }
            ITapiocaOptionBroker(data.removeAndRepayData.exitData.target).exitPosition(
                data.removeAndRepayData.exitData.oTAPTokenID
            );

            if (!data.removeAndRepayData.unlockData.unlock) {
                address tOLPContract = ITapiocaOptionBroker(data.removeAndRepayData.exitData.target).tOLP();

                //transfer tOLP to the data.user
                IERC721(tOLPContract).safeTransferFrom(address(this), data.user, tOLPId, "0x");
            }
        }

        // performs a tOLP.unlock operation
        if (data.removeAndRepayData.unlockData.unlock) {
            if (!cluster.isWhitelisted(0, data.removeAndRepayData.unlockData.target)) {
                revert Magnetar_TargetNotWhitelisted(data.removeAndRepayData.unlockData.target);
            }

            if (data.removeAndRepayData.unlockData.tokenId != 0) {
                if (tOLPId != 0) {
                    if (tOLPId != data.removeAndRepayData.unlockData.tokenId) {
                        revert Magnetar_tOLPTokenMismatch();
                    }
                }
                tOLPId = data.removeAndRepayData.unlockData.tokenId;
            }

            address ownerOfTOLP = IERC721(data.removeAndRepayData.unlockData.target).ownerOf(tOLPId);

            if (ownerOfTOLP != data.user && ownerOfTOLP != address(this)) {
                revert Magnetar_ActionParamsMismatch();
            }

            ITapiocaOptionLiquidityProvision(data.removeAndRepayData.unlockData.target).unlock(
                tOLPId, data.externalData.singularity, data.user
            );
        }

        // if `data.removeAndRepayData.removeAssetFromSGL` performs the follow operations:
        //      - removeAsset from SGL
        //      - if `data.removeAndRepayData.assetWithdrawData.withdraw` withdraws by using the `withdrawTo` operation
        uint256 _removeAmount = data.removeAndRepayData.removeAmount;
        if (data.removeAndRepayData.removeAssetFromSGL) {
            uint256 _assetId = singularity_.assetId();
            uint256 share = yieldBox_.toShare(_assetId, _removeAmount, false);

            address removeAssetTo = data.removeAndRepayData.assetWithdrawData.withdraw
                || data.removeAndRepayData.repayAssetOnBB ? address(this) : data.user;

            singularity_.removeAsset(data.user, removeAssetTo, share);

            //withdraw
            if (data.removeAndRepayData.assetWithdrawData.withdraw) {
                uint256 computedAmount = yieldBox_.toAmount(_assetId, share, false);
                data.removeAndRepayData.assetWithdrawData.lzSendParams.sendParam.amountLD = computedAmount;
                data.removeAndRepayData.assetWithdrawData.lzSendParams.sendParam.minAmountLD = computedAmount;
                _withdrawToChain(data.removeAndRepayData.assetWithdrawData);
            }
        }

        // performs a BigBang repay operation
        if (!data.removeAndRepayData.assetWithdrawData.withdraw && data.removeAndRepayData.repayAssetOnBB) {
            _setApprovalForYieldBox(address(bigBang_), yieldBox_);
            uint256 repayed = bigBang_.repay(address(this), data.user, false, data.removeAndRepayData.repayAmount);
            // transfer excess amount to the data.user
            if (repayed < _removeAmount) {
                uint256 bbAssetId = bigBang_.assetId();
                yieldBox_.transfer(
                    address(this), data.user, bbAssetId, yieldBox_.toShare(bbAssetId, _removeAmount - repayed, false)
                );
            }
        }

        // performs a BigBang removeCollateral operation
        // if `data.removeAndRepayData.collateralWithdrawData.withdraw` withdraws by using the `withdrawTo` method
        if (data.removeAndRepayData.removeCollateralFromBB) {
            uint256 _collateralId = bigBang_.collateralId();
            uint256 collateralShare = yieldBox_.toShare(_collateralId, data.removeAndRepayData.collateralAmount, false);
            address removeCollateralTo =
                data.removeAndRepayData.collateralWithdrawData.withdraw ? address(this) : data.user;
            bigBang_.removeCollateral(data.user, removeCollateralTo, collateralShare);

            //withdraw
            if (data.removeAndRepayData.collateralWithdrawData.withdraw) {
                uint256 computedAmount = yieldBox_.toAmount(_collateralId, collateralShare, false);
                data.removeAndRepayData.collateralWithdrawData.lzSendParams.sendParam.amountLD = computedAmount;
                data.removeAndRepayData.collateralWithdrawData.lzSendParams.sendParam.minAmountLD = computedAmount;
                _withdrawToChain(data.removeAndRepayData.collateralWithdrawData);
            }
        }
        _revertYieldBoxApproval(address(bigBang_), yieldBox_);
    }
}
