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
    MagnetarWithdrawData,
    ICommonExternalContracts,
    IRemoveAndRepay
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {TapiocaOmnichainEngineCodec} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainEngineCodec.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOption} from "tapioca-periph/interfaces/tap-token/ITapiocaOption.sol";
import {IMarketHelper} from "tapioca-periph/interfaces/bar/IMarketHelper.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {MagnetarBaseModuleExternal} from "./MagnetarBaseModuleExternal.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IMarket, Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {SendParamsMsg} from "tapioca-periph/interfaces/oft/ITOFT.sol";
import {ITOFT} from "tapioca-periph/interfaces/oft/ITOFT.sol";
import {MagnetarStorage} from "../MagnetarStorage.sol";

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
contract MagnetarOptionModule is Ownable, MagnetarStorage {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    error Magnetar_ActionParamsMismatch();
    error Magnetar_tOLPTokenMismatch();
    error Magnetar_MarketCallFailed(bytes call);
    error Magnetar_ExtractTokenFail();
    error Magnetar_ComposeMsgNotAllowed();
    error Magnetar_UserMismatch();

    address immutable magnetarBaseModuleExternal;

    constructor(address _magnetarBaseModuleExternal) MagnetarStorage(IPearlmit(address(0))) {
        magnetarBaseModuleExternal = _magnetarBaseModuleExternal;
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
        // validate data
        _validateExitPositionAndRemoveCollateral(data);

        IMarket bigBang_ = IMarket(data.externalData.bigBang);
        ISingularity singularity_ = ISingularity(data.externalData.singularity);
        IYieldBox yieldBox_ = data.externalData.singularity != address(0)
            ? IYieldBox(singularity_._yieldBox())
            : IYieldBox(bigBang_._yieldBox());

        _executeDelegateCall(
            magnetarBaseModuleExternal,
            abi.encodeWithSelector(
                MagnetarBaseModuleExternal.setApprovalForYieldBox.selector, address(bigBang_), yieldBox_
            )
        );

        _executeDelegateCall(
            magnetarBaseModuleExternal,
            abi.encodeWithSelector(
                MagnetarBaseModuleExternal.setApprovalForYieldBox.selector, address(pearlmit), yieldBox_
            )
        );

        // if `removeAndRepayData.exitData.exit` the following operations are performed
        //      - if ownerOfTapTokenId is user, transfers the oTAP token id to this contract
        //      - tOB.exitPosition
        //      - if `!removeAndRepayData.unlockData.unlock`, transfer the obtained tokenId to the user
        uint256 tOLPId = 0;
        if (data.removeAndRepayData.exitData.exit) {
            address oTapAddress = ITapiocaOptionBroker(data.removeAndRepayData.exitData.target).oTAP();
            (, ITapiocaOption.TapOption memory oTAPPosition) =
                ITapiocaOption(oTapAddress).attributes(data.removeAndRepayData.exitData.oTAPTokenID);

            tOLPId = oTAPPosition.tOLP;

            address ownerOfTapTokenId = IERC721(oTapAddress).ownerOf(data.removeAndRepayData.exitData.oTAPTokenID);

            if (ownerOfTapTokenId != data.user && ownerOfTapTokenId != address(this)) {
                revert Magnetar_ActionParamsMismatch();
            }
            if (ownerOfTapTokenId == data.user) {
                // IERC721(oTapAddress).safeTransferFrom(
                //     data.user, address(this), data.removeAndRepayData.exitData.oTAPTokenID, "0x"
                // );
                bool isErr = pearlmit.transferFromERC721(
                    data.user, address(this), oTapAddress, data.removeAndRepayData.exitData.oTAPTokenID
                );
                if (isErr) revert Magnetar_ExtractTokenFail();
            }
            IERC721(oTapAddress).approve(
                data.removeAndRepayData.exitData.target, data.removeAndRepayData.exitData.oTAPTokenID
            );
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
            uint256 _assetId = singularity_._assetId();

            address removeAssetTo = data.removeAndRepayData.assetWithdrawData.withdraw
                && !data.removeAndRepayData.repayAssetOnBB ? address(this) : data.user;

            // convert share to fraction
            singularity_.accrue();
            uint256 fraction = helper.getFractionForAmount(singularity_, _removeAmount);

            uint256 share = singularity_.removeAsset(data.user, removeAssetTo, fraction);

            //withdraw
            if (data.removeAndRepayData.assetWithdrawData.withdraw) {
                // assure unwrap is false because asset is not a TOFT
                if (data.removeAndRepayData.assetWithdrawData.compose) revert Magnetar_ComposeMsgNotAllowed();

                uint256 computedAmount = yieldBox_.toAmount(_assetId, share, false);
                data.removeAndRepayData.assetWithdrawData.lzSendParams.sendParam.amountLD = computedAmount;
                data.removeAndRepayData.assetWithdrawData.lzSendParams.sendParam.minAmountLD =
                    ITOFT(singularity_._asset()).removeDust(computedAmount);

                // already validated above
                // _withdrawToChain(data.removeAndRepayData.assetWithdrawData);
                _executeDelegateCall(
                    magnetarBaseModuleExternal,
                    abi.encodeWithSelector(
                        MagnetarBaseModuleExternal.withdrawToChain.selector, data.removeAndRepayData.assetWithdrawData
                    )
                );
            }
        }

        // performs a BigBang repay operation
        if (!data.removeAndRepayData.assetWithdrawData.withdraw && data.removeAndRepayData.repayAssetOnBB) {
            (Module[] memory modules, bytes[] memory calls) = IMarketHelper(data.externalData.marketHelper).repay(
                data.user,
                data.user,
                false,
                helper.getBorrowPartForAmount(data.externalData.bigBang, data.removeAndRepayData.repayAmount)
            );

            {
                uint256 bbAssetId = bigBang_._assetId();
                pearlmit.approve(
                    address(yieldBox_),
                    bbAssetId,
                    address(bigBang_),
                    uint200(data.removeAndRepayData.repayAmount),
                    (block.timestamp).toUint48()
                ); // TODO check approval
                (bool[] memory successes, bytes[] memory results) = bigBang_.execute(modules, calls, true);
                if (!successes[0]) revert Magnetar_MarketCallFailed(calls[0]);

                uint256 repayed = IMarketHelper(data.externalData.marketHelper).repayView(results[0]);
                // transfer excess amount to the data.user
                if (repayed < _removeAmount) {
                    yieldBox_.transfer(
                        address(this),
                        data.user,
                        bbAssetId,
                        yieldBox_.toShare(bbAssetId, _removeAmount - repayed, false)
                    );
                }
            }
        }

        // performs a BigBang removeCollateral operation
        // if `data.removeAndRepayData.collateralWithdrawData.withdraw` withdraws by using the `withdrawTo` method
        if (data.removeAndRepayData.removeCollateralFromBB) {
            uint256 _collateralId = bigBang_._collateralId();
            uint256 collateralShare = yieldBox_.toShare(_collateralId, data.removeAndRepayData.collateralAmount, false);
            address removeCollateralTo =
                data.removeAndRepayData.collateralWithdrawData.withdraw ? address(this) : data.user;

            (Module[] memory modules, bytes[] memory calls) = IMarketHelper(data.externalData.marketHelper)
                .removeCollateral(data.user, removeCollateralTo, collateralShare);
            bigBang_.execute(modules, calls, true);

            //withdraw
            if (data.removeAndRepayData.collateralWithdrawData.withdraw) {
                if (data.removeAndRepayData.collateralWithdrawData.compose) {
                    // allow only unwrap receiver
                    (,,, bytes memory tapComposeMsg_,) = TapiocaOmnichainEngineCodec.decodeToeComposeMsg(
                        data.removeAndRepayData.collateralWithdrawData.lzSendParams.sendParam.composeMsg
                    );

                    // it should fail at this point if data != SendParamsMsg
                    SendParamsMsg memory unwrapReceiverData = abi.decode(tapComposeMsg_, (SendParamsMsg));
                    if (unwrapReceiverData.receiver != data.user) revert Magnetar_UserMismatch();
                }

                uint256 computedAmount = yieldBox_.toAmount(_collateralId, collateralShare, false);
                data.removeAndRepayData.collateralWithdrawData.lzSendParams.sendParam.amountLD = computedAmount;
                data.removeAndRepayData.collateralWithdrawData.lzSendParams.sendParam.minAmountLD =
                    ITOFT(bigBang_._collateral()).removeDust(computedAmount);

                // _withdrawToChain(data.removeAndRepayData.collateralWithdrawData);
                _executeDelegateCall(
                    magnetarBaseModuleExternal,
                    abi.encodeWithSelector(
                        MagnetarBaseModuleExternal.withdrawToChain.selector,
                        data.removeAndRepayData.collateralWithdrawData
                    )
                );
            }
        }
        // _revertYieldBoxApproval(address(bigBang_), yieldBox_);
        _executeDelegateCall(
            magnetarBaseModuleExternal,
            abi.encodeWithSelector(
                MagnetarBaseModuleExternal.revertYieldBoxApproval.selector, address(bigBang_), yieldBox_
            )
        );

        _executeDelegateCall(
            magnetarBaseModuleExternal,
            abi.encodeWithSelector(
                MagnetarBaseModuleExternal.revertYieldBoxApproval.selector, address(pearlmit), yieldBox_
            )
        );
    }

    function _executeDelegateCall(address _target, bytes memory _data) internal returns (bytes memory returnData) {
        bool success = true;
        (success, returnData) = _target.delegatecall(_data);
        if (!success) {
            _getRevertMsg(returnData);
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
    }
}
