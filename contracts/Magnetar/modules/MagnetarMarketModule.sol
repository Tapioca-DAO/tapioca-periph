// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// LZ
import {LzLib} from "contracts/tmp/LzLib.sol";

//TAPIOCA
import {ITapiocaOptionLiquidityProvision} from "contracts/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ITapiocaOptionBroker} from "contracts/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ITapiocaOption} from "contracts/interfaces/tap-token/ITapiocaOption.sol";
import {ITapiocaOFT} from "contracts/interfaces/tap-token/ITapiocaOFT.sol";
import {ICommonData} from "contracts/interfaces/common/ICommonData.sol";
import {ISingularity} from "contracts/interfaces/bar/ISingularity.sol";
import {ICommonOFT} from "contracts/interfaces/common/ICommonOFT.sol";
import {IYieldBox} from "contracts/interfaces/yieldBox/IYieldBox.sol";
import {ISendFrom} from "contracts/interfaces/common/ISendFrom.sol";
import {ICluster} from "contracts/interfaces/periph/ICluster.sol";
import {IMarket} from "contracts/interfaces/bar/IMarket.sol";
import {IUSDOBase} from "contracts/interfaces/bar/IUSDO.sol";
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
    error Failed();
    error GasMismatch();

    function withdrawToChain(WithdrawToChainData calldata _data) external payable {
        _withdrawToChain(_data);
    }

    function depositAddCollateralAndBorrowFromMarket(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        ICommonData.IWithdrawParams calldata withdrawParams,
        uint256 valueAmount
    ) external payable {
        _depositAddCollateralAndBorrowFromMarket(
            market, user, collateralAmount, borrowAmount, extractFromSender, deposit, withdrawParams, valueAmount
        );
    }

    function depositRepayAndRemoveCollateralFromMarket(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool extractFromSender,
        ICommonData.IWithdrawParams calldata withdrawCollateralParams,
        uint256 valueAmount
    ) external payable {
        _depositRepayAndRemoveCollateralFromMarket(
            market,
            user,
            depositAmount,
            repayAmount,
            collateralAmount,
            extractFromSender,
            withdrawCollateralParams,
            valueAmount
        );
    }

    function mintFromBBAndLendOnSGL(
        address user,
        uint256 lendAmount,
        IUSDOBase.IMintData calldata mintData,
        ICommonData.IDepositData calldata depositData,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionBroker.IOptionsParticipateData calldata participateData,
        ICommonData.ICommonExternalContracts calldata externalContracts,
        ICluster _cluster
    ) external payable {
        _mintFromBBAndLendOnSGL(
            user, lendAmount, mintData, depositData, lockData, participateData, externalContracts, _cluster
        );
    }

    function exitPositionAndRemoveCollateral(
        address user,
        ICommonData.ICommonExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData,
        uint256 valueAmount,
        ICluster _cluster
    ) external payable {
        _exitPositionAndRemoveCollateral(user, externalData, removeAndRepayData, valueAmount, _cluster);
    }

    // *********************** //
    // *** PRIVATE METHODS *** //
    // *********************** //
    function _depositAddCollateralAndBorrowFromMarket(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        ICommonData.IWithdrawParams calldata withdrawParams,
        uint256 valueAmount
    ) private {
        if (!cluster.isWhitelisted(cluster.lzChainId(), address(market))) {
            revert NotAuthorized();
        }

        IYieldBox yieldBox = IYieldBox(market.yieldBox());

        uint256 collateralId = market.collateralId();
        (, address collateralAddress,,) = yieldBox.assets(collateralId);

        uint256 _share = yieldBox.toShare(collateralId, collateralAmount, false);
        //deposit to YieldBox
        if (deposit) {
            // transfers tokens from sender or from the user to this contract
            collateralAmount =
                _extractTokens(extractFromSender ? msg.sender : user, collateralAddress, collateralAmount);
            _share = yieldBox.toShare(collateralId, collateralAmount, false);

            // deposit to YieldBox
            IERC20(collateralAddress).approve(address(yieldBox), 0);
            IERC20(collateralAddress).approve(address(yieldBox), collateralAmount);
            yieldBox.depositAsset(collateralId, address(this), address(this), collateralAmount, 0);
        }

        // performs .addCollateral on market
        if (collateralAmount > 0) {
            _setApprovalForYieldBox(address(market), yieldBox);
            market.addCollateral(deposit ? address(this) : user, user, false, collateralAmount, _share);
        }

        // performs .borrow on market
        // if `withdraw` it uses `withdrawTo` to withdraw assets on the same chain or to another one
        if (borrowAmount > 0) {
            address borrowReceiver = withdrawParams.withdraw ? address(this) : user;
            market.borrow(user, borrowReceiver, borrowAmount);

            if (withdrawParams.withdraw) {
                bytes memory withdrawAssetBytes = abi.encode(
                    withdrawParams.withdrawOnOtherChain,
                    withdrawParams.withdrawLzChainId,
                    LzLib.addressToBytes32(user),
                    withdrawParams.withdrawAdapterParams
                );
                _withdraw(
                    borrowReceiver,
                    withdrawAssetBytes,
                    market,
                    yieldBox,
                    borrowAmount,
                    false,
                    valueAmount,
                    false,
                    withdrawParams.refundAddress,
                    withdrawParams.zroPaymentAddress
                );
            }
        }

        _revertYieldBoxApproval(address(market), yieldBox);
    }

    function _depositRepayAndRemoveCollateralFromMarket(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool extractFromSender,
        ICommonData.IWithdrawParams calldata withdrawCollateralParams,
        uint256 valueAmount
    ) private {
        if (!cluster.isWhitelisted(cluster.lzChainId(), address(market))) {
            revert NotAuthorized();
        }

        IMarket marketInterface = IMarket(market);
        IYieldBox yieldBox = IYieldBox(marketInterface.yieldBox());

        uint256 assetId = marketInterface.assetId();
        (, address assetAddress,,) = yieldBox.assets(assetId);

        // deposit to YieldBox
        if (depositAmount > 0) {
            depositAmount = _extractTokens(extractFromSender ? msg.sender : user, assetAddress, depositAmount);
            IERC20(assetAddress).approve(address(yieldBox), 0);
            IERC20(assetAddress).approve(address(yieldBox), depositAmount);
            yieldBox.depositAsset(assetId, address(this), address(this), depositAmount, 0);
        }

        // performs a repay operation for the specified market
        if (repayAmount > 0) {
            _setApprovalForYieldBox(market, yieldBox);
            marketInterface.repay(depositAmount > 0 ? address(this) : user, user, false, repayAmount);
            _revertYieldBoxApproval(market, yieldBox);
        }

        // performs a removeCollateral operation on the market
        // if `withdrawCollateralParams.withdraw` it uses `withdrawTo` to withdraw collateral on the same chain or to another one
        if (collateralAmount > 0) {
            address collateralWithdrawReceiver = withdrawCollateralParams.withdraw ? address(this) : user;
            uint256 collateralShare = yieldBox.toShare(marketInterface.collateralId(), collateralAmount, false);
            marketInterface.removeCollateral(user, collateralWithdrawReceiver, collateralShare);

            uint256 collateralId = marketInterface.collateralId();
            //withdraw
            if (withdrawCollateralParams.withdraw) {
                _withdrawToChain(
                    WithdrawToChainData({
                        yieldBox: yieldBox,
                        from: collateralWithdrawReceiver,
                        assetId: collateralId,
                        dstChainId: withdrawCollateralParams.withdrawLzChainId,
                        receiver: LzLib.addressToBytes32(user),
                        amount: yieldBox.toAmount(collateralId, collateralShare, false),
                        adapterParams: withdrawCollateralParams.withdrawAdapterParams,
                        refundAddress: withdrawCollateralParams.refundAddress,
                        gas: valueAmount,
                        unwrap: withdrawCollateralParams.unwrap,
                        zroPaymentAddress: withdrawCollateralParams.zroPaymentAddress
                    })
                );
            }
        }
    }

    function _mintFromBBAndLendOnSGL(
        address user,
        uint256 lendAmount,
        IUSDOBase.IMintData memory mintData,
        ICommonData.IDepositData memory depositData,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionBroker.IOptionsParticipateData calldata participateData,
        ICommonData.ICommonExternalContracts calldata externalContracts,
        ICluster _cluster
    ) private {
        IMarket bigBang = IMarket(externalContracts.bigBang);
        ISingularity singularity = ISingularity(externalContracts.singularity);
        IYieldBox yieldBox = IYieldBox(singularity.yieldBox());

        if (externalContracts.bigBang != address(0)) {
            if (!_cluster.isWhitelisted(_cluster.lzChainId(), externalContracts.bigBang)) revert NotAuthorized();
        }
        if (externalContracts.singularity != address(0)) {
            if (!_cluster.isWhitelisted(_cluster.lzChainId(), externalContracts.singularity)) revert NotAuthorized();
        }

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
        if (mintData.mint) {
            uint256 bbCollateralId = bigBang.collateralId();
            (, address bbCollateralAddress,,) = yieldBox.assets(bbCollateralId);
            uint256 bbCollateralShare = yieldBox.toShare(bbCollateralId, mintData.collateralDepositData.amount, false);
            // deposit collateral to YB
            if (mintData.collateralDepositData.deposit) {
                mintData.collateralDepositData.amount = _extractTokens(
                    mintData.collateralDepositData.extractFromSender ? msg.sender : user,
                    bbCollateralAddress,
                    mintData.collateralDepositData.amount
                );
                bbCollateralShare = yieldBox.toShare(bbCollateralId, mintData.collateralDepositData.amount, false);

                IERC20(bbCollateralAddress).approve(address(yieldBox), 0);
                IERC20(bbCollateralAddress).approve(address(yieldBox), mintData.collateralDepositData.amount);
                yieldBox.depositAsset(
                    bbCollateralId, address(this), address(this), mintData.collateralDepositData.amount, 0
                );
            }

            // add collateral to BB
            if (mintData.collateralDepositData.amount > 0) {
                //add collateral to BingBang
                _setApprovalForYieldBox(address(bigBang), yieldBox);
                bigBang.addCollateral(
                    mintData.collateralDepositData.deposit ? address(this) : user,
                    user,
                    false,
                    mintData.collateralDepositData.amount,
                    bbCollateralShare
                );
            }

            // mints from BB
            bigBang.borrow(user, user, mintData.mintAmount);
        }

        // if `depositData.deposit`:
        //      - deposit SGL asset to YB for `user`
        uint256 sglAssetId = singularity.assetId();
        (, address sglAssetAddress,,) = yieldBox.assets(sglAssetId);
        if (depositData.deposit) {
            depositData.amount =
                _extractTokens(depositData.extractFromSender ? msg.sender : user, sglAssetAddress, depositData.amount);

            IERC20(sglAssetAddress).approve(address(yieldBox), 0);
            IERC20(sglAssetAddress).approve(address(yieldBox), depositData.amount);
            yieldBox.depositAsset(sglAssetId, address(this), user, depositData.amount, 0);
        }

        // if `lendAmount` > 0:
        //      - add asset to SGL
        uint256 fraction = 0;
        if (lendAmount == 0 && depositData.deposit) {
            lendAmount = depositData.amount;
        }
        if (lendAmount > 0) {
            uint256 lendShare = yieldBox.toShare(sglAssetId, lendAmount, false);
            fraction = singularity.addAsset(user, user, false, lendShare);
        }

        // if `lockData.lock`:
        //      - transfer `fraction` from user to `address(this)
        //      - deposits `fraction` to YB for `address(this)`
        //      - performs tOLP.lock
        uint256 tOLPTokenId = 0;
        if (lockData.lock) {
            if (!_cluster.isWhitelisted(_cluster.lzChainId(), lockData.target)) {
                revert NotAuthorized();
            }
            if (lockData.fraction > 0) {
                fraction = lockData.fraction;
            }
            // retrieve and deposit SGLAssetId registered in tOLP
            (uint256 tOLPSglAssetId,,) =
                ITapiocaOptionLiquidityProvision(lockData.target).activeSingularities(address(singularity));
            if (fraction == 0) revert NotValid();
            IERC20(address(singularity)).safeTransferFrom(user, address(this), fraction);
            IERC20(address(singularity)).approve(address(yieldBox), 0);
            IERC20(address(singularity)).approve(address(yieldBox), fraction);
            yieldBox.depositAsset(tOLPSglAssetId, address(this), address(this), fraction, 0);

            _setApprovalForYieldBox(lockData.target, yieldBox);
            address lockTo = participateData.participate ? address(this) : user;
            tOLPTokenId = ITapiocaOptionLiquidityProvision(lockData.target).lock(
                lockTo, address(singularity), lockData.lockDuration, lockData.amount
            );
            _revertYieldBoxApproval(lockData.target, yieldBox);
        }

        // if `participateData.participate`:
        //      - verify tOLPTokenId
        //      - performs tOB.participate
        //      - transfer `oTAPTokenId` to user
        if (participateData.participate) {
            if (!_cluster.isWhitelisted(_cluster.lzChainId(), participateData.target)) revert NotAuthorized();

            if (participateData.tOLPTokenId != 0) {
                if (tOLPTokenId != 0) {
                    if (participateData.tOLPTokenId != tOLPTokenId) {
                        revert tOLPTokenMismatch();
                    }
                }

                tOLPTokenId = participateData.tOLPTokenId;
            }
            if (lockData.target == address(0)) revert LockTargetMismatch();
            if (tOLPTokenId == 0) revert NotValid();

            IERC721(lockData.target).approve(participateData.target, tOLPTokenId);
            uint256 oTAPTokenId = ITapiocaOptionBroker(participateData.target).participate(tOLPTokenId);

            address oTapAddress = ITapiocaOptionBroker(participateData.target).oTAP();
            IERC721(oTapAddress).safeTransferFrom(address(this), user, oTAPTokenId, "0x");
        }

        if (address(singularity) != address(0)) {
            _revertYieldBoxApproval(address(singularity), yieldBox);
        }
        if (address(bigBang) != address(0)) {
            _revertYieldBoxApproval(address(bigBang), yieldBox);
        }
    }

    function _exitPositionAndRemoveCollateral(
        address user,
        ICommonData.ICommonExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData,
        uint256 valueAmount,
        ICluster _cluster
    ) private {
        if (externalData.bigBang != address(0)) {
            if (!_cluster.isWhitelisted(_cluster.lzChainId(), externalData.bigBang)) revert NotAuthorized();
        }
        if (externalData.singularity != address(0)) {
            if (!_cluster.isWhitelisted(_cluster.lzChainId(), externalData.singularity)) revert NotAuthorized();
        }

        IMarket bigBang = IMarket(externalData.bigBang);
        ISingularity singularity = ISingularity(externalData.singularity);
        IYieldBox yieldBox = IYieldBox(singularity.yieldBox());

        // if `removeAndRepayData.exitData.exit` the following operations are performed
        //      - if ownerOfTapTokenId is user, transfers the oTAP token id to this contract
        //      - tOB.exitPosition
        //      - if `!removeAndRepayData.unlockData.unlock`, transfer the obtained tokenId to the user
        uint256 tOLPId = 0;
        if (removeAndRepayData.exitData.exit) {
            if (removeAndRepayData.exitData.oTAPTokenID == 0) revert NotValid();
            if (!_cluster.isWhitelisted(_cluster.lzChainId(), removeAndRepayData.exitData.target)) {
                revert NotAuthorized();
            }

            address oTapAddress = ITapiocaOptionBroker(removeAndRepayData.exitData.target).oTAP();
            (, ITapiocaOption.TapOption memory oTAPPosition) =
                ITapiocaOption(oTapAddress).attributes(removeAndRepayData.exitData.oTAPTokenID);

            tOLPId = oTAPPosition.tOLP;

            address ownerOfTapTokenId = IERC721(oTapAddress).ownerOf(removeAndRepayData.exitData.oTAPTokenID);

            if (ownerOfTapTokenId != user && ownerOfTapTokenId != address(this)) {
                revert NotValid();
            }
            if (ownerOfTapTokenId == user) {
                IERC721(oTapAddress).safeTransferFrom(
                    user, address(this), removeAndRepayData.exitData.oTAPTokenID, "0x"
                );
            }
            ITapiocaOptionBroker(removeAndRepayData.exitData.target).exitPosition(
                removeAndRepayData.exitData.oTAPTokenID
            );

            if (!removeAndRepayData.unlockData.unlock) {
                address tOLPContract = ITapiocaOptionBroker(removeAndRepayData.exitData.target).tOLP();

                //transfer tOLP to the user
                IERC721(tOLPContract).safeTransferFrom(address(this), user, tOLPId, "0x");
            }
        }

        // performs a tOLP.unlock operation
        if (removeAndRepayData.unlockData.unlock) {
            if (!_cluster.isWhitelisted(_cluster.lzChainId(), removeAndRepayData.unlockData.target)) {
                revert NotAuthorized();
            }

            if (removeAndRepayData.unlockData.tokenId != 0) {
                if (tOLPId != 0) {
                    if (tOLPId != removeAndRepayData.unlockData.tokenId) {
                        revert tOLPTokenMismatch();
                    }
                }
                tOLPId = removeAndRepayData.unlockData.tokenId;
            }

            address ownerOfTOLP = IERC721(removeAndRepayData.unlockData.target).ownerOf(tOLPId);

            if (ownerOfTOLP != user && ownerOfTOLP != address(this)) {
                revert NotValid();
            }

            ITapiocaOptionLiquidityProvision(removeAndRepayData.unlockData.target).unlock(
                tOLPId, externalData.singularity, user
            );
        }

        // if `removeAndRepayData.removeAssetFromSGL` performs the follow operations:
        //      - removeAsset from SGL
        //      - if `removeAndRepayData.assetWithdrawData.withdraw` withdraws by using the `withdrawTo` operation
        uint256 _removeAmount = removeAndRepayData.removeAmount;
        if (removeAndRepayData.removeAssetFromSGL) {
            uint256 _assetId = singularity.assetId();
            uint256 share = yieldBox.toShare(_assetId, _removeAmount, false);

            address removeAssetTo = removeAndRepayData.assetWithdrawData.withdraw || removeAndRepayData.repayAssetOnBB
                ? address(this)
                : user;

            singularity.removeAsset(user, removeAssetTo, share);

            //withdraw
            if (removeAndRepayData.assetWithdrawData.withdraw) {
                bytes memory withdrawAssetBytes = abi.encode(
                    removeAndRepayData.assetWithdrawData.withdrawOnOtherChain,
                    removeAndRepayData.assetWithdrawData.withdrawLzChainId,
                    LzLib.addressToBytes32(user),
                    removeAndRepayData.assetWithdrawData.withdrawAdapterParams
                );
                _withdraw(
                    address(this),
                    withdrawAssetBytes,
                    singularity,
                    yieldBox,
                    yieldBox.toAmount(_assetId, share, false), // re-compute amount to avoid rounding issues
                    false,
                    valueAmount,
                    false,
                    removeAndRepayData.assetWithdrawData.refundAddress,
                    removeAndRepayData.assetWithdrawData.zroPaymentAddress
                );
            }
        }

        // performs a BigBang repay operation
        if (!removeAndRepayData.assetWithdrawData.withdraw && removeAndRepayData.repayAssetOnBB) {
            _setApprovalForYieldBox(address(bigBang), yieldBox);
            uint256 repayed = bigBang.repay(address(this), user, false, removeAndRepayData.repayAmount);
            // transfer excess amount to the user
            if (repayed < _removeAmount) {
                yieldBox.transfer(
                    address(this),
                    user,
                    bigBang.assetId(),
                    yieldBox.toShare(bigBang.assetId(), _removeAmount - repayed, false)
                );
            }
        }

        // performs a BigBang removeCollateral operation
        // if `removeAndRepayData.collateralWithdrawData.withdraw` withdraws by using the `withdrawTo` method
        if (removeAndRepayData.removeCollateralFromBB) {
            uint256 _collateralId = bigBang.collateralId();
            uint256 collateralShare = yieldBox.toShare(_collateralId, removeAndRepayData.collateralAmount, false);
            address removeCollateralTo = removeAndRepayData.collateralWithdrawData.withdraw ? address(this) : user;
            bigBang.removeCollateral(user, removeCollateralTo, collateralShare);

            //withdraw
            if (removeAndRepayData.collateralWithdrawData.withdraw) {
                bytes memory withdrawCollateralBytes = abi.encode(
                    removeAndRepayData.collateralWithdrawData.withdrawOnOtherChain,
                    removeAndRepayData.collateralWithdrawData.withdrawLzChainId,
                    LzLib.addressToBytes32(user),
                    removeAndRepayData.collateralWithdrawData.withdrawAdapterParams
                );
                _withdraw(
                    address(this),
                    withdrawCollateralBytes,
                    singularity,
                    yieldBox,
                    yieldBox.toAmount(_collateralId, collateralShare, false), // re-compute amount to avoid rounding issues
                    true,
                    valueAmount,
                    removeAndRepayData.collateralWithdrawData.unwrap,
                    removeAndRepayData.collateralWithdrawData.refundAddress,
                    removeAndRepayData.collateralWithdrawData.zroPaymentAddress
                );
            }
        }
        _revertYieldBoxApproval(address(bigBang), yieldBox);
    }

    /// @dev Calldata for `_withdrawToChain`
    struct WithdrawToChainData {
        IYieldBox yieldBox;
        address from;
        uint256 assetId;
        uint16 dstChainId;
        bytes32 receiver;
        uint256 amount;
        bytes adapterParams;
        address payable refundAddress;
        uint256 gas;
        bool unwrap;
        address zroPaymentAddress;
    }

    /// @notice performs a withdraw operation
    /// @dev it can withdraw on the current chain or it can send it to another one
    ///     - if `dstChainId` is 0 performs a same-chain withdrawal
    ///          - all parameters except `yieldBox`, `from`, `assetId` and `amount` or `share` are ignored
    ///     - if `dstChainId` is NOT 0, the method requires gas for the `sendFrom` operation
    /// @param _data.yieldBox the YieldBox address
    /// @param _data.from user to withdraw from
    /// @param _data.assetId the YieldBox asset id to withdraw
    /// @param _data.dstChainId LZ chain id to withdraw to
    /// @param _data.receiver the receiver on the destination chain
    /// @param _data.amount the amount to withdraw
    /// @param _data.adapterParams LZ adapter params
    /// @param _data.refundAddress the LZ refund address which receives the gas not used in the process
    /// @param _data.gas the amount of gas to use for sending the asset to another layer
    /// @param _data.unwrap if withdrawn asset is a TOFT, it can be unwrapped on destination
    /// @param _data.zroPaymentAddress ZRO payment address
    function _withdrawToChain(WithdrawToChainData memory _data) private {
        if (!cluster.isWhitelisted(cluster.lzChainId(), address(_data.yieldBox))) {
            revert NotAuthorized();
        }

        // perform a same chain withdrawal
        if (_data.dstChainId == 0) {
            _withdrawOnThisChain(_data.yieldBox, _data.assetId, _data.from, _data.receiver, _data.amount);
            return;
        }

        if (msg.value > 0) {
            if (msg.value != _data.gas) revert GasMismatch();
        }
        // perform a cross chain withdrawal
        (, address asset,,) = _data.yieldBox.assets(_data.assetId);
        // withdraw from YieldBox
        _data.yieldBox.withdraw(_data.assetId, _data.from, address(this), _data.amount, 0);

        // build LZ params
        bytes memory adapterParams;
        ICommonOFT.LzCallParams memory callParams = ICommonOFT.LzCallParams({
            refundAddress: _data.refundAddress,
            zroPaymentAddress: _data.zroPaymentAddress,
            adapterParams: ISendFrom(address(asset)).useCustomAdapterParams() ? adapterParams : adapterParams
        });

        if (!cluster.isWhitelisted(cluster.lzChainId(), address(asset))) {
            revert NotAuthorized();
        }
        // sends the asset to another layer
        if (_data.unwrap) {
            ICommonData.IApproval[] memory approvals = new ICommonData.IApproval[](0);
            try ITapiocaOFT(address(asset)).sendFromWithParams{value: _data.gas}(
                address(this), _data.dstChainId, _data.receiver, _data.amount, callParams, true, approvals, approvals
            ) {} catch {
                _withdrawOnThisChain(_data.yieldBox, _data.assetId, _data.from, _data.receiver, _data.amount);
            }
        } else {
            try ISendFrom(address(asset)).sendFrom{value: _data.gas}(
                address(this), _data.dstChainId, _data.receiver, _data.amount, callParams
            ) {} catch {
                _withdrawOnThisChain(_data.yieldBox, _data.assetId, _data.from, _data.receiver, _data.amount);
            }
        }
    }

    function _withdrawOnThisChain(IYieldBox yieldBox, uint256 assetId, address from, bytes32 receiver, uint256 amount)
        private
    {
        yieldBox.withdraw(assetId, from, LzLib.bytes32ToAddress(receiver), amount, 0);
    }

    function _withdraw(
        address from,
        bytes memory withdrawData,
        IMarket market,
        IYieldBox yieldBox,
        uint256 amount,
        bool withdrawCollateral,
        uint256 valueAmount,
        bool unwrap,
        address payable refundAddress,
        address zroPaymentAddress
    ) private {
        if (withdrawData.length == 0) revert NotValid();
        (bool withdrawOnOtherChain, uint16 destChain, bytes32 receiver, bytes memory adapterParams) =
            abi.decode(withdrawData, (bool, uint16, bytes32, bytes));

        _withdrawToChain(
            WithdrawToChainData({
                yieldBox: yieldBox,
                from: from,
                assetId: withdrawCollateral ? market.collateralId() : market.assetId(),
                dstChainId: withdrawOnOtherChain ? destChain : 0,
                receiver: receiver,
                amount: amount,
                adapterParams: adapterParams,
                refundAddress: refundAddress,
                gas: valueAmount,
                unwrap: unwrap,
                zroPaymentAddress: zroPaymentAddress
            })
        );
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

    function _extractTokens(address _from, address _token, uint256 _amount) private returns (uint256) {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        if (balanceAfter <= balanceBefore) revert Failed();
        return balanceAfter - balanceBefore;
    }
}
