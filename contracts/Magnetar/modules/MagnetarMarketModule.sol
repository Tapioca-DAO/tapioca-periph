// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//LZ
import "tapioca-sdk/dist/contracts/libraries/LzLib.sol";

//OZ
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//TAPIOCA
import "../../interfaces/IYieldBoxBase.sol";

import "../MagnetarV2Storage.sol";

contract MagnetarMarketModule is MagnetarV2Storage {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    function withdrawTo(
        IYieldBoxBase yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        uint256 share,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas
    ) external payable {
        _withdrawTo(
            yieldBox,
            from,
            assetId,
            dstChainId,
            receiver,
            amount,
            share,
            adapterParams,
            refundAddress,
            gas
        );
    }

    function depositAddCollateralAndBorrow(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        bool withdraw,
        bytes memory withdrawData
    ) external payable {
        _depositAddCollateralAndBorrow(
            market,
            user,
            collateralAmount,
            borrowAmount,
            extractFromSender,
            deposit,
            withdraw,
            withdrawData
        );
    }

    function depositAndRepay(
        IMarket market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        bool deposit,
        bool extractFromSender
    ) external payable {
        _depositAndRepay(
            market,
            user,
            depositAmount,
            repayAmount,
            deposit,
            extractFromSender
        );
    }

    function depositRepayAndRemoveCollateral(
        IMarket market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool deposit,
        bool withdraw,
        bool extractFromSender
    ) external payable {
        _depositRepayAndRemoveCollateral(
            market,
            user,
            depositAmount,
            repayAmount,
            collateralAmount,
            deposit,
            withdraw,
            extractFromSender
        );
    }

    function mintAndLend(
        ISingularity singularity,
        IMarket bingBang,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool deposit,
        bool extractFromSender
    ) external payable {
        _mintAndLend(
            singularity,
            bingBang,
            user,
            collateralAmount,
            borrowAmount,
            deposit,
            extractFromSender
        );
    }

    function depositAndAddAsset(
        IMarket singularity,
        address user,
        uint256 amount,
        bool deposit,
        bool extractFromSender,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionsBroker.IOptionsParticipateData calldata participateData
    ) external payable {
        _depositAndAddAsset(
            singularity,
            user,
            amount,
            deposit,
            extractFromSender,
            lockData,
            participateData
        );
    }

    function removeAssetAndRepay(
        address user,
        IUSDOBase.IRemoveAndRepayExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData
    ) external payable {
        _removeAssetAndRepay(user, externalData, removeAndRepayData);
    }

    // *********************** //
    // *** PRIVATE METHODS *** //
    // *********************** //
    function _depositAddCollateralAndBorrow(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        bool withdraw,
        bytes memory withdrawData
    ) private {
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        uint256 collateralId = market.collateralId();

        (, address collateralAddress, , ) = yieldBox.assets(collateralId);

        //deposit into the yieldbox
        uint256 _share = yieldBox.toShare(
            collateralId,
            collateralAmount,
            false
        );
        if (deposit) {
            if (!extractFromSender) {
                _checkSender(user);
            }
            _extractTokens(
                extractFromSender ? msg.sender : user,
                collateralAddress,
                collateralAmount
            );
            IERC20(collateralAddress).approve(
                address(yieldBox),
                collateralAmount
            );
            yieldBox.depositAsset(
                collateralId,
                address(this),
                address(this),
                0,
                _share
            );
        }

        //add collateral
        if (collateralAmount > 0) {
            _setApprovalForYieldBox(address(market), yieldBox);
            market.addCollateral(
                deposit ? address(this) : user,
                user,
                false,
                collateralAmount,
                _share
            );
        }

        //borrow
        if (borrowAmount > 0) {
            address borrowReceiver = withdraw ? address(this) : user;
            market.borrow(user, borrowReceiver, borrowAmount);

            if (withdraw) {
                _withdraw(
                    borrowReceiver,
                    withdrawData,
                    market,
                    yieldBox,
                    borrowAmount,
                    0,
                    false
                );
            }
        }

        _revertYieldBoxApproval(address(market), yieldBox);
    }

    function _depositAndRepay(
        IMarket market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        bool deposit,
        bool extractFromSender
    ) private {
        uint256 assetId = market.assetId();
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        (, address assetAddress, , ) = yieldBox.assets(assetId);

        //deposit into the yieldbox
        if (deposit) {
            _extractTokens(
                extractFromSender ? msg.sender : user,
                assetAddress,
                depositAmount
            );
            IERC20(assetAddress).approve(address(yieldBox), depositAmount);
            yieldBox.depositAsset(
                assetId,
                address(this),
                address(this),
                depositAmount,
                0
            );
        }

        //repay
        if (repayAmount > 0) {
            _setApprovalForYieldBox(address(market), yieldBox);
            market.repay(
                deposit ? address(this) : user,
                user,
                false,
                repayAmount
            );
            _revertYieldBoxApproval(address(market), yieldBox);
        }
    }

    function _depositRepayAndRemoveCollateral(
        IMarket market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool deposit,
        bool withdraw,
        bool extractFromSender
    ) private {
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        _depositAndRepay(
            market,
            user,
            depositAmount,
            repayAmount,
            deposit,
            extractFromSender
        );

        //remove collateral
        if (collateralAmount > 0) {
            address receiver = withdraw ? address(this) : user;
            uint256 collateralShare = yieldBox.toShare(
                market.collateralId(),
                collateralAmount,
                false
            );
            market.removeCollateral(user, receiver, collateralShare);

            //withdraw
            if (withdraw) {
                yieldBox.withdraw(
                    market.collateralId(),
                    address(this),
                    user,
                    collateralAmount,
                    0
                );
            }
        }
    }

    function _mintAndLend(
        ISingularity singularity,
        IMarket bingBang,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool deposit,
        bool extractFromSender
    ) private {
        uint256 collateralId = bingBang.collateralId();
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        (, address collateralAddress, , ) = yieldBox.assets(collateralId);
        uint256 _share = yieldBox.toShare(
            collateralId,
            collateralAmount,
            false
        );

        if (deposit) {
            //deposit to YieldBox
            _extractTokens(
                extractFromSender ? msg.sender : user,
                collateralAddress,
                collateralAmount
            );
            IERC20(collateralAddress).approve(
                address(yieldBox),
                collateralAmount
            );
            yieldBox.depositAsset(
                collateralId,
                address(this),
                address(this),
                0,
                _share
            );
        }

        if (collateralAmount > 0) {
            //add collateral to BingBang
            _setApprovalForYieldBox(address(bingBang), yieldBox);
            bingBang.addCollateral(
                address(this),
                user,
                false,
                collateralAmount,
                _share
            );
        }

        //borrow from BingBang
        if (borrowAmount > 0) {
            bingBang.borrow(user, user, borrowAmount);

            //lend to Singularity
            uint256 assetId = singularity.assetId();
            uint256 borrowShare = yieldBox.toShare(
                assetId,
                borrowAmount,
                false
            );
            _setApprovalForYieldBox(address(singularity), yieldBox);
            singularity.addAsset(user, user, false, borrowShare);
            _revertYieldBoxApproval(address(singularity), yieldBox);
        }
        _revertYieldBoxApproval(address(bingBang), yieldBox);
    }

    function _depositAndAddAsset(
        IMarket singularity,
        address user,
        uint256 amount,
        bool deposit_,
        bool extractFromSender,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionsBroker.IOptionsParticipateData calldata participateData
    ) private {
        uint256 assetId = singularity.assetId();
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        (, address assetAddress, , ) = yieldBox.assets(assetId);

        uint256 _share = yieldBox.toShare(assetId, amount, false);
        if (deposit_) {
            if (!extractFromSender) {
                _checkSender(user);
            }
            //deposit into the yieldbox
            _extractTokens(
                extractFromSender ? msg.sender : user,
                assetAddress,
                amount
            );
            IERC20(assetAddress).approve(address(yieldBox), amount);
            yieldBox.depositAsset(
                assetId,
                address(this),
                address(this),
                0,
                _share
            );
        }

        //add asset
        // address addAssetTo = lockData.lock ? address(this) : user;
        _setApprovalForYieldBox(address(singularity), yieldBox);
        uint256 fraction = singularity.addAsset(
            address(this),
            user,
            false,
            _share
        );

        //lock
        uint256 tOLPTokenId = 0;
        if (lockData.lock) {
            // retrieve and deposit SGLAssetId registered in tOLP
            (uint256 sglAssetId, , ) = ITapiocaOptionLiquidityProvision(
                lockData.target
            ).activeSingularities(address(singularity));
            IERC20(address(singularity)).safeTransferFrom(
                user,
                address(this),
                fraction
            );
            IERC20(address(singularity)).approve(address(yieldBox), fraction);
            yieldBox.depositAsset(
                sglAssetId,
                address(this),
                address(this),
                fraction,
                0
            );

            _setApprovalForYieldBox(lockData.target, yieldBox);
            address lockTo = participateData.participate ? address(this) : user;
            tOLPTokenId = ITapiocaOptionLiquidityProvision(lockData.target)
                .lock(
                    lockTo,
                    address(singularity),
                    lockData.lockDuration,
                    lockData.amount
                );
            _revertYieldBoxApproval(lockData.target, yieldBox);
        }

        if (participateData.participate) {
            require(tOLPTokenId != 0, "Magnetar: tOLPTokenId 0");
            IERC721(lockData.target).approve(
                participateData.target,
                tOLPTokenId
            );
            uint256 oTAPTokenId = ITapiocaOptionsBroker(participateData.target)
                .participate(tOLPTokenId);

            address oTapAddress = ITapiocaOptionsBroker(participateData.target)
                .oTAP();
            IERC721(oTapAddress).approve(address(this), oTAPTokenId);
            IERC721(oTapAddress).safeTransferFrom(
                address(this),
                user,
                oTAPTokenId,
                "0x"
            );
        }

        _revertYieldBoxApproval(address(singularity), yieldBox);
    }

    function _removeAssetAndRepay(
        address user,
        IUSDOBase.IRemoveAndRepayExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData
    ) private {
        IMarket bigBang = IMarket(externalData.bigBang);
        ISingularity singularity = ISingularity(externalData.singularity);
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        uint256 bbAssetId = bigBang.assetId();
        uint256 sglAssetId = singularity.assetId();
        require(bbAssetId == sglAssetId, "Magnetar: assets mismatch");

        // tOB exit position
        if (removeAndRepayData.exitData.exit) {
            //TODO: add code
        }

        // tOLP unlock
        if (removeAndRepayData.unlockData.unlock) {
            //TODO: add code
        }

        //remove asset from SGL
        uint256 _removeAmount = 0;
        if (removeAndRepayData.removeAssetFromSGL) {
            _removeAmount = yieldBox.toAmount(
                sglAssetId,
                removeAndRepayData.removeShare,
                false
            );

            address removeAssetTo = removeAndRepayData
                .assetWithdrawData
                .withdraw || removeAndRepayData.repayAssetOnBB
                ? address(this)
                : user;
            uint256 removedShare = singularity.removeAsset(
                user,
                removeAssetTo,
                removeAndRepayData.removeShare
            );

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
                    0,
                    removedShare,
                    true
                );
            }
        }

        //repay on BB
        if (
            !removeAndRepayData.assetWithdrawData.withdraw &&
            removeAndRepayData.repayAssetOnBB
        ) {
            _setApprovalForYieldBox(address(bigBang), yieldBox);
            uint256 repayed = bigBang.repay(
                address(this),
                user,
                false,
                removeAndRepayData.repayAmount
            );
            if (repayed < _removeAmount) {
                yieldBox.transfer(
                    address(this),
                    user,
                    bbAssetId,
                    yieldBox.toShare(bbAssetId, _removeAmount - repayed, false)
                );
            }
        }

        //remove collateral from BB
        if (removeAndRepayData.removeCollateralFromBB) {
            address removeCollateralTo = removeAndRepayData
                .collateralWithdrawData
                .withdraw
                ? address(this)
                : user;
            bigBang.removeCollateral(
                user,
                removeCollateralTo,
                removeAndRepayData.collateralShare
            );

            //withdraw
            if (removeAndRepayData.collateralWithdrawData.withdraw) {
                bytes memory withdrawCollateralBytes = abi.encode(
                    removeAndRepayData
                        .collateralWithdrawData
                        .withdrawOnOtherChain,
                    removeAndRepayData.collateralWithdrawData.withdrawLzChainId,
                    LzLib.addressToBytes32(user),
                    removeAndRepayData
                        .collateralWithdrawData
                        .withdrawAdapterParams
                );
                _withdraw(
                    address(this),
                    withdrawCollateralBytes,
                    singularity,
                    yieldBox,
                    0,
                    removeAndRepayData.collateralShare,
                    true
                );
            }
        }
        _revertYieldBoxApproval(address(bigBang), yieldBox);
    }

    function _withdrawTo(
        IYieldBoxBase yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        uint256 share,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas
    ) private {
        if (dstChainId == 0) {
            yieldBox.withdraw(
                assetId,
                from,
                LzLib.bytes32ToAddress(receiver),
                amount,
                share
            );
            return;
        }
        (, address asset, , ) = yieldBox.assets(assetId);
        try
            IERC165(address(asset)).supportsInterface(
                type(ISendFrom).interfaceId
            )
        {} catch {
            return;
        }

        yieldBox.withdraw(assetId, from, address(this), amount, 0);
        bytes memory _adapterParams;
        ISendFrom.LzCallParams memory callParams = ISendFrom.LzCallParams({
            refundAddress: msg.value > 0 ? refundAddress : payable(this),
            zroPaymentAddress: address(0),
            adapterParams: ISendFrom(address(asset)).useCustomAdapterParams()
                ? adapterParams
                : _adapterParams
        });
        ISendFrom(address(asset)).sendFrom{value: gas}(
            address(this),
            dstChainId,
            receiver,
            amount,
            callParams
        );
    }

    function _withdraw(
        address from,
        bytes memory withdrawData,
        IMarket market,
        IYieldBoxBase yieldBox,
        uint256 amount,
        uint256 share,
        bool withdrawCollateral
    ) private {
        require(withdrawData.length > 0, "MagnetarV2: withdrawData is empty");
        (
            bool withdrawOnOtherChain,
            uint16 destChain,
            bytes32 receiver,
            bytes memory adapterParams
        ) = abi.decode(withdrawData, (bool, uint16, bytes32, bytes));

        uint256 gas = msg.value > 0 ? msg.value : address(this).balance;
        _withdrawTo(
            yieldBox,
            from,
            withdrawCollateral ? market.collateralId() : market.assetId(),
            withdrawOnOtherChain ? destChain : 0,
            receiver,
            amount,
            share,
            adapterParams,
            gas > 0 ? payable(msg.sender) : payable(this),
            gas
        );
    }

    function _setApprovalForYieldBox(
        address target,
        IYieldBoxBase yieldBox
    ) private {
        bool isApproved = yieldBox.isApprovedForAll(
            address(this),
            address(target)
        );
        if (!isApproved) {
            yieldBox.setApprovalForAll(address(target), true);
        }
    }

    function _revertYieldBoxApproval(
        address target,
        IYieldBoxBase yieldBox
    ) private {
        bool isApproved = yieldBox.isApprovedForAll(
            address(this),
            address(target)
        );
        if (isApproved) {
            yieldBox.setApprovalForAll(address(target), false);
        }
    }

    function _extractTokens(
        address _from,
        address _token,
        uint256 _amount
    ) private {
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
    }
}
