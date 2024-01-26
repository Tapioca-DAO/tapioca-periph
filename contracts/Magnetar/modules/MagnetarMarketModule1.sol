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
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {IUSDOBase} from "tapioca-periph/interfaces/bar/IUSDO.sol";

import {MagnetarMarketModuleBase} from "./MagnetarMarketModuleBase.sol";

contract MagnetarMarketModule1 is MagnetarMarketModuleBase {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error tOLPTokenMismatch();

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
                _withdrawPrepare(
                    _WithdrawPrepareData({
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
}
