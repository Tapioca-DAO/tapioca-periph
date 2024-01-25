// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// LZ
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";
import {LzLib} from "tapioca-periph/tmp/LzLib.sol";

//TAPIOCA
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOption} from "tapioca-periph/interfaces/tap-token/ITapiocaOption.sol";
import {ICommonData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldBox/IYieldBox.sol";
import {MagnetarYieldboxModule} from "./MagnetarYieldboxModule.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {IUSDOBase} from "tapioca-periph/interfaces/bar/IUSDO.sol";

import {MagnetarMarketModuleBase} from "./MagnetarMarketModuleBase.sol";

contract MagnetarMarketModule2 is MagnetarMarketModuleBase {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error tOLPTokenMismatch();

    /// @dev Parse a burst call
    fallback() external payable {
        bytes4 funcSig = bytes4(BytesLib.slice(msg.data, 0, 4));
        bytes memory callWithoutSelector = BytesLib.slice(msg.data, 4, msg.data.length - 4);

        if (funcSig == this.depositRepayAndRemoveCollateralFromMarket.selector) {
            depositRepayAndRemoveCollateralFromMarket(
                abi.decode(callWithoutSelector, (DepositRepayAndRemoveCollateralFromMarketData))
            );
        }
        if (funcSig == this.exitPositionAndRemoveCollateral.selector) {
            exitPositionAndRemoveCollateral(abi.decode(callWithoutSelector, (ExitPositionAndRemoveCollateralData)));
        }
    }

    // *********************** //
    // *** PUBLIC METHODS ***  //
    // *********************** //

    /**
     * @dev `depositRepayAndRemoveCollateralFromMarket` calldata
     */
    struct DepositRepayAndRemoveCollateralFromMarketData {
        IMarket market;
        address user;
        uint256 depositAmount;
        uint256 repayAmount;
        uint256 collateralAmount;
        bool extractFromSender;
        ICommonData.IWithdrawParams withdrawCollateralParams;
        uint256 valueAmount;
    }

    /**
     * @notice helper for deposit asset to YieldBox, repay on a market, remove collateral and withdraw
     * @dev all steps are optional:
     *         - if `depositAmount` is 0, the deposit to YieldBox step is skipped
     *         - if `repayAmount` is 0, the repay step is skipped
     *         - if `collateralAmount` is 0, the add collateral step is skipped
     *
     * @param _data.market the SGL/BigBang market
     * @param _data.user the user to perform the action for
     * @param _data.depositAmount the amount to deposit to YieldBox
     * @param _data.repayAmount the amount to repay to the market
     * @param _data.collateralAmount the amount to withdraw from the market
     * @param _data.extractFromSender extracts collateral tokens from sender or from the user
     * @param _data.withdrawCollateralParams withdraw specific params
     */
    function depositRepayAndRemoveCollateralFromMarket(DepositRepayAndRemoveCollateralFromMarketData memory _data)
        public
        payable
    {
        // Check sender
        _checkSender(_data.user);

        // Check target
        if (!cluster.isWhitelisted(cluster.lzChainId(), address(_data.market))) {
            revert TargetNotWhitelisted(address(_data.market));
        }

        IYieldBox yieldBox = IYieldBox(_data.market.yieldBox());

        uint256 assetId = _data.market.assetId();
        (, address assetAddress,,) = yieldBox.assets(assetId);

        // deposit to YieldBox
        if (_data.depositAmount > 0) {
            _data.depositAmount =
                _extractTokens(_data.extractFromSender ? msg.sender : _data.user, assetAddress, _data.depositAmount);
            IERC20(assetAddress).approve(address(yieldBox), 0);
            IERC20(assetAddress).approve(address(yieldBox), _data.depositAmount);
            yieldBox.depositAsset(assetId, address(this), address(this), _data.depositAmount, 0);
        }

        // performs a repay operation for the specified market
        if (_data.repayAmount > 0) {
            _setApprovalForYieldBox(address(_data.market), yieldBox);
            _data.market.repay(
                _data.depositAmount > 0 ? address(this) : _data.user, _data.user, false, _data.repayAmount
            );
            _revertYieldBoxApproval(address(_data.market), yieldBox);
        }

        // performs a removeCollateral operation on the market
        // if `withdrawCollateralParams.withdraw` it uses `withdrawTo` to withdraw collateral on the same chain or to another one
        if (_data.collateralAmount > 0) {
            address collateralWithdrawReceiver = _data.withdrawCollateralParams.withdraw ? address(this) : _data.user;
            uint256 collateralShare = yieldBox.toShare(_data.market.collateralId(), _data.collateralAmount, false);
            _data.market.removeCollateral(_data.user, collateralWithdrawReceiver, collateralShare);

            uint256 collateralId = _data.market.collateralId();
            //withdraw
            if (_data.withdrawCollateralParams.withdraw) {
                _withdrawToChain(
                    MagnetarYieldboxModule.WithdrawToChainData({
                        yieldBox: yieldBox,
                        from: collateralWithdrawReceiver,
                        assetId: collateralId,
                        dstChainId: _data.withdrawCollateralParams.withdrawLzChainId,
                        receiver: LzLib.addressToBytes32(_data.user),
                        amount: yieldBox.toAmount(collateralId, collateralShare, false),
                        adapterParams: _data.withdrawCollateralParams.withdrawAdapterParams,
                        refundAddress: _data.withdrawCollateralParams.refundAddress,
                        gas: _data.valueAmount,
                        unwrap: _data.withdrawCollateralParams.unwrap,
                        zroPaymentAddress: _data.withdrawCollateralParams.zroPaymentAddress
                    })
                );
            }
        }
    }

    /**
     * @dev `exitPositionAndRemoveCollateral` calldata
     */
    struct ExitPositionAndRemoveCollateralData {
        address user;
        ICommonData.ICommonExternalContracts externalData;
        IUSDOBase.IRemoveAndRepay removeAndRepayData;
        uint256 valueAmount;
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
    function exitPositionAndRemoveCollateral(ExitPositionAndRemoveCollateralData memory _data) public payable {
        // Check sender
        _checkSender(_data.user);

        // Check whitelisted
        if (_data.externalData.bigBang != address(0)) {
            if (!cluster.isWhitelisted(cluster.lzChainId(), _data.externalData.bigBang)) {
                revert TargetNotWhitelisted(_data.externalData.bigBang);
            }
        }
        if (_data.externalData.singularity != address(0)) {
            if (!cluster.isWhitelisted(cluster.lzChainId(), _data.externalData.singularity)) {
                revert TargetNotWhitelisted(_data.externalData.singularity);
            }
        }

        IMarket bigBang = IMarket(_data.externalData.bigBang);
        ISingularity singularity = ISingularity(_data.externalData.singularity);
        IYieldBox yieldBox = IYieldBox(singularity.yieldBox());

        // if `removeAndRepayData.exitData.exit` the following operations are performed
        //      - if ownerOfTapTokenId is user, transfers the oTAP token id to this contract
        //      - tOB.exitPosition
        //      - if `!removeAndRepayData.unlockData.unlock`, transfer the obtained tokenId to the user
        uint256 tOLPId = 0;
        if (_data.removeAndRepayData.exitData.exit) {
            if (_data.removeAndRepayData.exitData.oTAPTokenID == 0) revert NotValid();
            if (!cluster.isWhitelisted(cluster.lzChainId(), _data.removeAndRepayData.exitData.target)) {
                revert TargetNotWhitelisted(_data.removeAndRepayData.exitData.target);
            }

            address oTapAddress = ITapiocaOptionBroker(_data.removeAndRepayData.exitData.target).oTAP();
            (, ITapiocaOption.TapOption memory oTAPPosition) =
                ITapiocaOption(oTapAddress).attributes(_data.removeAndRepayData.exitData.oTAPTokenID);

            tOLPId = oTAPPosition.tOLP;

            address ownerOfTapTokenId = IERC721(oTapAddress).ownerOf(_data.removeAndRepayData.exitData.oTAPTokenID);

            if (ownerOfTapTokenId != _data.user && ownerOfTapTokenId != address(this)) {
                revert NotValid();
            }
            if (ownerOfTapTokenId == _data.user) {
                IERC721(oTapAddress).safeTransferFrom(
                    _data.user, address(this), _data.removeAndRepayData.exitData.oTAPTokenID, "0x"
                );
            }
            ITapiocaOptionBroker(_data.removeAndRepayData.exitData.target).exitPosition(
                _data.removeAndRepayData.exitData.oTAPTokenID
            );

            if (!_data.removeAndRepayData.unlockData.unlock) {
                address tOLPContract = ITapiocaOptionBroker(_data.removeAndRepayData.exitData.target).tOLP();

                //transfer tOLP to the _data.user
                IERC721(tOLPContract).safeTransferFrom(address(this), _data.user, tOLPId, "0x");
            }
        }

        // performs a tOLP.unlock operation
        if (_data.removeAndRepayData.unlockData.unlock) {
            if (!cluster.isWhitelisted(cluster.lzChainId(), _data.removeAndRepayData.unlockData.target)) {
                revert TargetNotWhitelisted(_data.removeAndRepayData.unlockData.target);
            }

            if (_data.removeAndRepayData.unlockData.tokenId != 0) {
                if (tOLPId != 0) {
                    if (tOLPId != _data.removeAndRepayData.unlockData.tokenId) {
                        revert tOLPTokenMismatch();
                    }
                }
                tOLPId = _data.removeAndRepayData.unlockData.tokenId;
            }

            address ownerOfTOLP = IERC721(_data.removeAndRepayData.unlockData.target).ownerOf(tOLPId);

            if (ownerOfTOLP != _data.user && ownerOfTOLP != address(this)) {
                revert NotValid();
            }

            ITapiocaOptionLiquidityProvision(_data.removeAndRepayData.unlockData.target).unlock(
                tOLPId, _data.externalData.singularity, _data.user
            );
        }

        // if `_data.removeAndRepayData.removeAssetFromSGL` performs the follow operations:
        //      - removeAsset from SGL
        //      - if `_data.removeAndRepayData.assetWithdrawData.withdraw` withdraws by using the `withdrawTo` operation
        uint256 _removeAmount = _data.removeAndRepayData.removeAmount;
        if (_data.removeAndRepayData.removeAssetFromSGL) {
            uint256 _assetId = singularity.assetId();
            uint256 share = yieldBox.toShare(_assetId, _removeAmount, false);

            address removeAssetTo = _data.removeAndRepayData.assetWithdrawData.withdraw
                || _data.removeAndRepayData.repayAssetOnBB ? address(this) : _data.user;

            singularity.removeAsset(_data.user, removeAssetTo, share);

            //withdraw
            if (_data.removeAndRepayData.assetWithdrawData.withdraw) {
                bytes memory withdrawAssetBytes = abi.encode(
                    _data.removeAndRepayData.assetWithdrawData.withdrawOnOtherChain,
                    _data.removeAndRepayData.assetWithdrawData.withdrawLzChainId,
                    LzLib.addressToBytes32(_data.user),
                    _data.removeAndRepayData.assetWithdrawData.withdrawAdapterParams
                );
                _withdrawPrepare(
                    _WithdrawPrepareData({
                        from: address(this),
                        withdrawData: withdrawAssetBytes,
                        market: singularity,
                        yieldBox: yieldBox,
                        amount: yieldBox.toAmount(_assetId, share, false), // re-compute amount to avoid rounding issues
                        withdrawCollateral: false,
                        valueAmount: _data.valueAmount,
                        unwrap: false,
                        refundAddress: _data.removeAndRepayData.assetWithdrawData.refundAddress,
                        zroPaymentAddress: _data.removeAndRepayData.assetWithdrawData.zroPaymentAddress
                    })
                );
            }
        }

        // performs a BigBang repay operation
        if (!_data.removeAndRepayData.assetWithdrawData.withdraw && _data.removeAndRepayData.repayAssetOnBB) {
            _setApprovalForYieldBox(address(bigBang), yieldBox);
            uint256 repayed = bigBang.repay(address(this), _data.user, false, _data.removeAndRepayData.repayAmount);
            // transfer excess amount to the _data.user
            if (repayed < _removeAmount) {
                yieldBox.transfer(
                    address(this),
                    _data.user,
                    bigBang.assetId(),
                    yieldBox.toShare(bigBang.assetId(), _removeAmount - repayed, false)
                );
            }
        }

        // performs a BigBang removeCollateral operation
        // if `_data.removeAndRepayData.collateralWithdrawData.withdraw` withdraws by using the `withdrawTo` method
        if (_data.removeAndRepayData.removeCollateralFromBB) {
            uint256 _collateralId = bigBang.collateralId();
            uint256 collateralShare = yieldBox.toShare(_collateralId, _data.removeAndRepayData.collateralAmount, false);
            address removeCollateralTo =
                _data.removeAndRepayData.collateralWithdrawData.withdraw ? address(this) : _data.user;
            bigBang.removeCollateral(_data.user, removeCollateralTo, collateralShare);

            //withdraw
            if (_data.removeAndRepayData.collateralWithdrawData.withdraw) {
                bytes memory withdrawCollateralBytes = abi.encode(
                    _data.removeAndRepayData.collateralWithdrawData.withdrawOnOtherChain,
                    _data.removeAndRepayData.collateralWithdrawData.withdrawLzChainId,
                    LzLib.addressToBytes32(_data.user),
                    _data.removeAndRepayData.collateralWithdrawData.withdrawAdapterParams
                );
                _withdrawPrepare(
                    _WithdrawPrepareData({
                        from: address(this),
                        withdrawData: withdrawCollateralBytes,
                        market: singularity,
                        yieldBox: yieldBox,
                        amount: yieldBox.toAmount(_collateralId, collateralShare, false), // re-compute amount to avoid rounding issues
                        withdrawCollateral: true,
                        valueAmount: _data.valueAmount,
                        unwrap: _data.removeAndRepayData.collateralWithdrawData.unwrap,
                        refundAddress: _data.removeAndRepayData.collateralWithdrawData.refundAddress,
                        zroPaymentAddress: _data.removeAndRepayData.collateralWithdrawData.zroPaymentAddress
                    })
                );
            }
        }
        _revertYieldBoxApproval(address(bigBang), yieldBox);
    }
}
