// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// LZ
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";
import {LzLib} from "tapioca-periph/tmp/LzLib.sol";

//TAPIOCA
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOption} from "tapioca-periph/interfaces/tap-token/ITapiocaOption.sol";
import {ITapiocaOFT} from "tapioca-periph/interfaces/tap-token/ITapiocaOFT.sol";
import {ICommonData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {ICommonOFT} from "tapioca-periph/interfaces/common/ICommonOFT.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldBox/IYieldBox.sol";
import {ISendFrom} from "tapioca-periph/interfaces/common/ISendFrom.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {MagnetarYieldboxModule} from "./MagnetarYieldboxModule.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {IUSDOBase} from "tapioca-periph/interfaces/bar/IUSDO.sol";

import {MagnetarV2Storage} from "../MagnetarV2Storage.sol";

contract MagnetarMarketModule is Ownable, MagnetarV2Storage {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error NotValid();
    error tOLPTokenMismatch();
    error LockTargetMismatch();
    error ExtractTokenFail(); // failed to extract tokens from sender or user. See `_extractTokens()`

    /// @dev Parse a burst call
    fallback() external payable {
        Call memory call = abi.decode(msg.data, (Call));
        bytes4 funcSig = bytes4(BytesLib.slice(call.call, 0, 4));
        bytes memory callWithoutSelector = BytesLib.slice(call.call, 4, call.call.length);

        if (funcSig == this.mintFromBBAndLendOnSGL.selector) {
            mintFromBBAndLendOnSGL(abi.decode(callWithoutSelector, (MintFromBBAndLendOnSGLData)));
        }
        if (funcSig == this.depositAddCollateralAndBorrowFromMarket.selector) {
            depositAddCollateralAndBorrowFromMarket(
                abi.decode(callWithoutSelector, (DepositAddCollateralAndBorrowFromMarketData))
            );
        }
        if (funcSig == this.exitPositionAndRemoveCollateral.selector) {
            exitPositionAndRemoveCollateral(abi.decode(callWithoutSelector, (ExitPositionAndRemoveCollateralData)));
        }
        if (funcSig == this.depositRepayAndRemoveCollateralFromMarket.selector) {
            depositRepayAndRemoveCollateralFromMarket(
                abi.decode(callWithoutSelector, (DepositRepayAndRemoveCollateralFromMarketData))
            );
        }
    }

    // *********************** //
    // *** PUBLIC METHODS ***  //
    // *********************** //

    /**
     * @dev `depositAddCollateralAndBorrowFromMarket` calldata
     */
    struct DepositAddCollateralAndBorrowFromMarketData {
        IMarket market;
        address user;
        uint256 collateralAmount;
        uint256 borrowAmount;
        bool extractFromSender;
        bool deposit;
        ICommonData.IWithdrawParams withdrawParams;
        uint256 valueAmount;
    }

    /**
     * @notice helper for deposit to YieldBox, add collateral to a market, borrow from the same market and withdraw
     * @dev all operations are optional:
     *         - if `deposit` is false it will skip the deposit to YieldBox step
     *         - if `withdraw` is false it will skip the withdraw step
     *         - if `collateralAmount == 0` it will skip the add collateral step
     *         - if `borrowAmount == 0` it will skip the borrow step
     *     - the amount deposited to YieldBox is `collateralAmount`
     *
     * @param _data.market the SGL/BigBang market
     * @param _data.user the user to perform the action for
     * @param _data.collateralAmount the collateral amount to add
     * @param _data.borrowAmount the borrow amount
     * @param _data.extractFromSender extracts collateral tokens from sender or from the user
     * @param _data.deposit true/false flag for the deposit to YieldBox step
     * @param _data.withdrawParams necessary data for the same chain or the cross-chain withdrawal
     */
    function depositAddCollateralAndBorrowFromMarket(DepositAddCollateralAndBorrowFromMarketData memory _data)
        public
        payable
    {
        // Check sender
        _checkSender(_data.user);

        // Check targets
        if (!cluster.isWhitelisted(cluster.lzChainId(), address(_data.market))) {
            revert TargetNotWhitelisted(address(_data.market));
        }

        IYieldBox yieldBox = IYieldBox(_data.market.yieldBox());

        uint256 collateralId = _data.market.collateralId();
        (, address collateralAddress,,) = yieldBox.assets(collateralId);

        uint256 _share = yieldBox.toShare(collateralId, _data.collateralAmount, false);
        //deposit to YieldBox
        if (_data.deposit) {
            // transfers tokens from sender or from the user to this contract
            _data.collateralAmount = _extractTokens(
                _data.extractFromSender ? msg.sender : _data.user, collateralAddress, _data.collateralAmount
            );
            _share = yieldBox.toShare(collateralId, _data.collateralAmount, false);

            // deposit to YieldBox
            IERC20(collateralAddress).approve(address(yieldBox), 0);
            IERC20(collateralAddress).approve(address(yieldBox), _data.collateralAmount);
            yieldBox.depositAsset(collateralId, address(this), address(this), _data.collateralAmount, 0);
        }

        // performs .addCollateral on _data.market
        if (_data.collateralAmount > 0) {
            _setApprovalForYieldBox(address(_data.market), yieldBox);
            _data.market.addCollateral(
                _data.deposit ? address(this) : _data.user, _data.user, false, _data.collateralAmount, _share
            );
        }

        // performs .borrow on _data.market
        // if `withdraw` it uses `withdrawTo` to withdraw assets on the same chain or to another one
        if (_data.borrowAmount > 0) {
            address borrowReceiver = _data.withdrawParams.withdraw ? address(this) : _data.user;
            _data.market.borrow(_data.user, borrowReceiver, _data.borrowAmount);

            if (_data.withdrawParams.withdraw) {
                bytes memory withdrawAssetBytes;
                {
                    withdrawAssetBytes = abi.encode(
                        _data.withdrawParams.withdrawOnOtherChain,
                        _data.withdrawParams.withdrawLzChainId,
                        LzLib.addressToBytes32(_data.user),
                        _data.withdrawParams.withdrawAdapterParams
                    );
                }
                _withdraw(
                    _WithdrawData({
                        from: borrowReceiver,
                        withdrawData: withdrawAssetBytes,
                        market: _data.market,
                        yieldBox: yieldBox,
                        amount: _data.borrowAmount,
                        withdrawCollateral: false,
                        valueAmount: _data.valueAmount,
                        unwrap: false,
                        refundAddress: _data.withdrawParams.refundAddress,
                        zroPaymentAddress: _data.withdrawParams.zroPaymentAddress
                    })
                );
            }
        }

        _revertYieldBoxApproval(address(_data.market), yieldBox);
    }

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
                _yieldBoxModule__WithdrawToChain(
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
     * @dev `mintFromBBAndLendOnSGL` calldata
     */
    struct MintFromBBAndLendOnSGLData {
        address user;
        uint256 lendAmount;
        IUSDOBase.IMintData mintData;
        ICommonData.IDepositData depositData;
        ITapiocaOptionLiquidityProvision.IOptionsLockData lockData;
        ITapiocaOptionBroker.IOptionsParticipateData participateData;
        ICommonData.ICommonExternalContracts externalContracts;
    }

    /**
     * @notice helper to deposit mint from BB, lend on SGL, lock on tOLP and participate on tOB
     * @dev all steps are optional:
     *         - if `mintData.mint` is false, the mint operation on BB is skipped
     *             - add BB collateral to YB, add collateral on BB and borrow from BB are part of the mint operation
     *         - if `depositData.deposit` is false, the asset deposit to YB is skipped
     *         - if `lendAmount == 0` the addAsset operation on SGL is skipped
     *             - if `mintData.mint` is true, `lendAmount` will be automatically filled with the minted value
     *         - if `lockData.lock` is false, the tOLP lock operation is skipped
     *         - if `participateData.participate` is false, the tOB participate operation is skipped
     *
     * @param _data.user the user to perform the operation for
     * @param _data.lendAmount the amount to lend on SGL
     * @param _data.mintData the data needed to mint on BB
     * @param _data.depositData the data needed for asset deposit on YieldBox
     * @param _data.lockData the data needed to lock on TapiocaOptionLiquidityProvision
     * @param _data.participateData the data needed to perform a participate operation on TapiocaOptionsBroker
     * @param _data.externalContracts the contracts' addresses used in all the operations performed by the helper
     */
    function mintFromBBAndLendOnSGL(MintFromBBAndLendOnSGLData memory _data) public payable {
        // Check sender
        _checkSender(_data.user);

        // Check targets
        if (_data.externalContracts.bigBang != address(0)) {
            if (!cluster.isWhitelisted(cluster.lzChainId(), _data.externalContracts.bigBang)) {
                revert TargetNotWhitelisted(_data.externalContracts.bigBang);
            }
        }
        if (_data.externalContracts.singularity != address(0)) {
            if (!cluster.isWhitelisted(cluster.lzChainId(), _data.externalContracts.singularity)) {
                revert TargetNotWhitelisted(_data.externalContracts.singularity);
            }
        }

        IMarket bigBang = IMarket(_data.externalContracts.bigBang);
        ISingularity singularity = ISingularity(_data.externalContracts.singularity);
        IYieldBox yieldBox = IYieldBox(singularity.yieldBox());

        if (address(singularity) != address(0)) {
            _setApprovalForYieldBox(address(singularity), yieldBox);
        }
        if (address(bigBang) != address(0)) {
            _setApprovalForYieldBox(address(bigBang), yieldBox);
        }

        // if `mint` was requested the following actions are performed:
        //  - extracts & deposits collateral to YB
        //  - performs bigBang.addCollateral
        //  - performs bigBang.borrow
        if (_data.mintData.mint) {
            uint256 bbCollateralId = bigBang.collateralId();
            (, address bbCollateralAddress,,) = yieldBox.assets(bbCollateralId);
            uint256 bbCollateralShare =
                yieldBox.toShare(bbCollateralId, _data.mintData.collateralDepositData.amount, false);
            // deposit collateral to YB
            if (_data.mintData.collateralDepositData.deposit) {
                _data.mintData.collateralDepositData.amount = _extractTokens(
                    _data.mintData.collateralDepositData.extractFromSender ? msg.sender : _data.user,
                    bbCollateralAddress,
                    _data.mintData.collateralDepositData.amount
                );
                bbCollateralShare = yieldBox.toShare(bbCollateralId, _data.mintData.collateralDepositData.amount, false);

                IERC20(bbCollateralAddress).approve(address(yieldBox), 0);
                IERC20(bbCollateralAddress).approve(address(yieldBox), _data.mintData.collateralDepositData.amount);
                yieldBox.depositAsset(
                    bbCollateralId, address(this), address(this), _data.mintData.collateralDepositData.amount, 0
                );
            }

            // add collateral to BB
            if (_data.mintData.collateralDepositData.amount > 0) {
                //add collateral to BingBang
                _setApprovalForYieldBox(address(bigBang), yieldBox);
                bigBang.addCollateral(
                    _data.mintData.collateralDepositData.deposit ? address(this) : _data.user,
                    _data.user,
                    false,
                    _data.mintData.collateralDepositData.amount,
                    bbCollateralShare
                );
            }

            // mints from BB
            bigBang.borrow(_data.user, _data.user, _data.mintData.mintAmount);
        }

        // if `depositData.deposit`:
        //      - deposit SGL asset to YB for `_data.user`
        uint256 sglAssetId = singularity.assetId();
        (, address sglAssetAddress,,) = yieldBox.assets(sglAssetId);
        if (_data.depositData.deposit) {
            _data.depositData.amount = _extractTokens(
                _data.depositData.extractFromSender ? msg.sender : _data.user, sglAssetAddress, _data.depositData.amount
            );

            IERC20(sglAssetAddress).approve(address(yieldBox), 0);
            IERC20(sglAssetAddress).approve(address(yieldBox), _data.depositData.amount);
            yieldBox.depositAsset(sglAssetId, address(this), _data.user, _data.depositData.amount, 0);
        }

        // if `lendAmount` > 0:
        //      - add asset to SGL
        uint256 fraction = 0;
        if (_data.lendAmount == 0 && _data.depositData.deposit) {
            _data.lendAmount = _data.depositData.amount;
        }
        if (_data.lendAmount > 0) {
            uint256 lendShare = yieldBox.toShare(sglAssetId, _data.lendAmount, false);
            fraction = singularity.addAsset(_data.user, _data.user, false, lendShare);
        }

        // if `lockData.lock`:
        //      - transfer `fraction` from _data.user to `address(this)
        //      - deposits `fraction` to YB for `address(this)`
        //      - performs tOLP.lock
        uint256 tOLPTokenId = 0;
        if (_data.lockData.lock) {
            if (!cluster.isWhitelisted(cluster.lzChainId(), _data.lockData.target)) {
                revert TargetNotWhitelisted(_data.lockData.target);
            }
            if (_data.lockData.fraction > 0) {
                fraction = _data.lockData.fraction;
            }
            // retrieve and deposit SGLAssetId registered in tOLP
            (uint256 tOLPSglAssetId,,) =
                ITapiocaOptionLiquidityProvision(_data.lockData.target).activeSingularities(address(singularity));
            if (fraction == 0) revert NotValid();
            IERC20(address(singularity)).safeTransferFrom(_data.user, address(this), fraction);
            IERC20(address(singularity)).approve(address(yieldBox), 0);
            IERC20(address(singularity)).approve(address(yieldBox), fraction);
            yieldBox.depositAsset(tOLPSglAssetId, address(this), address(this), fraction, 0);

            _setApprovalForYieldBox(_data.lockData.target, yieldBox);
            address lockTo = _data.participateData.participate ? address(this) : _data.user;
            tOLPTokenId = ITapiocaOptionLiquidityProvision(_data.lockData.target).lock(
                lockTo, address(singularity), _data.lockData.lockDuration, _data.lockData.amount
            );
            _revertYieldBoxApproval(_data.lockData.target, yieldBox);
        }

        // TODO improve this
        // if `participateData.participate`:
        //      - verify tOLPTokenId
        //      - performs tOB.participate
        //      - transfer `oTAPTokenId` to _data.user
        if (_data.participateData.participate) {
            // Check whitelisted
            if (!cluster.isWhitelisted(cluster.lzChainId(), _data.participateData.target)) {
                revert TargetNotWhitelisted(_data.participateData.target);
            }

            // Check tOLPTokenId
            if (_data.participateData.tOLPTokenId != 0) {
                if (tOLPTokenId != 0) {
                    if (_data.participateData.tOLPTokenId != tOLPTokenId) {
                        revert tOLPTokenMismatch();
                    }
                }

                tOLPTokenId = _data.participateData.tOLPTokenId;
            }
            if (tOLPTokenId == 0) revert NotValid();

            IERC721(_data.lockData.target).approve(_data.participateData.target, tOLPTokenId);
            uint256 oTAPTokenId = ITapiocaOptionBroker(_data.participateData.target).participate(tOLPTokenId);

            address oTapAddress = ITapiocaOptionBroker(_data.participateData.target).oTAP();
            IERC721(oTapAddress).safeTransferFrom(address(this), _data.user, oTAPTokenId, "0x");
        }

        if (address(singularity) != address(0)) {
            _revertYieldBoxApproval(address(singularity), yieldBox);
        }
        if (address(bigBang) != address(0)) {
            _revertYieldBoxApproval(address(bigBang), yieldBox);
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
                _withdraw(
                    _WithdrawData({
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
                _withdraw(
                    _WithdrawData({
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

    // ************************* //
    // *** INTERNAL METHODS ***  //
    // ************************* //

    /**
     * @dev `_withdraw` calldata
     */
    struct _WithdrawData {
        address from;
        bytes withdrawData;
        IMarket market;
        IYieldBox yieldBox;
        uint256 amount;
        bool withdrawCollateral;
        uint256 valueAmount;
        bool unwrap;
        address payable refundAddress;
        address zroPaymentAddress;
    }

    /**
     * @dev Performs a YieldBox withdrawal.
     * Can withdraw asset or collateral, on the same chain or on another one.
     *
     */
    function _withdraw(_WithdrawData memory _data) private {
        if (_data.withdrawData.length == 0) revert NotValid();
        (bool withdrawOnOtherChain, uint16 destChain, bytes32 receiver, bytes memory adapterParams) =
            abi.decode(_data.withdrawData, (bool, uint16, bytes32, bytes));

        // Prepare the call to the withdrawToChain method.
        // Most fields are not needed, we just to pass the encoded data
        MagnetarYieldboxModule.WithdrawToChainData memory withdrawToChainData = MagnetarYieldboxModule
            .WithdrawToChainData({
            yieldBox: _data.yieldBox,
            from: _data.from,
            assetId: _data.withdrawCollateral ? _data.market.collateralId() : _data.market.assetId(),
            dstChainId: withdrawOnOtherChain ? destChain : 0,
            receiver: receiver,
            amount: _data.amount,
            adapterParams: adapterParams,
            refundAddress: _data.refundAddress,
            gas: _data.valueAmount,
            unwrap: _data.unwrap,
            zroPaymentAddress: _data.zroPaymentAddress
        });
        _yieldBoxModule__WithdrawToChain(withdrawToChainData);
    }

    /**
     * @dev Call internally the withdrawToChain method of the YieldBox module.
     */
    function _yieldBoxModule__WithdrawToChain(MagnetarYieldboxModule.WithdrawToChainData memory _data) internal {
        // Prepare the call to the withdrawToChain method.
        // Most fields are not needed, we just to pass the encoded data
        Call memory call;
        call.call = abi.encodeWithSelector(MagnetarYieldboxModule.withdrawToChain.selector, _data);
        _executeModule(Module.Yieldbox, abi.encode(call));
    }

    function _setApprovalForYieldBox(address target, IYieldBox yieldBox) private {
        bool isApproved = yieldBox.isApprovedForAll(address(this), target);
        if (!isApproved) {
            yieldBox.setApprovalForAll(target, true);
        }
    }

    function _revertYieldBoxApproval(address target, IYieldBox yieldBox) private {
        bool isApproved = yieldBox.isApprovedForAll(address(this), address(target));
        if (isApproved) {
            yieldBox.setApprovalForAll(address(target), false);
        }
    }

    /**
     * @dev Extracts ERC20 tokens from `_from` to this contract.
     */
    function _extractTokens(address _from, address _token, uint256 _amount) private returns (uint256) {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        if (balanceAfter <= balanceBefore) revert ExtractTokenFail();
        return balanceAfter - balanceBefore;
    }
}
