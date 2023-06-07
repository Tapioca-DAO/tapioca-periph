// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//LZ
import "tapioca-sdk/dist/contracts/libraries/LzLib.sol";

//OZ
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//TAPIOCA
import "../../interfaces/IYieldBoxBase.sol";

import "../MagnetarV2Storage.sol";

contract MagnetarMarketModule is MagnetarV2Storage {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    /// @notice Update approval status for an operator
    /// @param operator The address approved to perform actions on your behalf
    /// @param approved True/False
    function setApprovalForAll(address operator, bool approved) public {
        // Checks
        require(operator != address(0), "MagnetarV2: operator not set"); 
        require(operator != address(this), "MagnetarV2: can't approve magnetar");

        // Effects
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
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
    ) external payable allowed(from) {
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
    ) external payable allowed(user){
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
    ) external payable allowed(user) {
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
    ) external payable allowed(user) {
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
    ) external payable allowed(user) {
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
        bool deposit_,
        bool extractFromSender
    ) external payable allowed(user){
        _depositAndAddAsset(
            singularity,
            user,
            amount,
            deposit_,
            extractFromSender
        );
    }

    function removeAssetAndRepay(
        ISingularity singularity,
        IMarket bingBang,
        address user,
        uint256 removeShare, //slightly greater than _repayAmount to cover the interest
        uint256 repayAmount,
        uint256 collateralShare,
        bool withdraw,
        bytes calldata withdrawData
    ) external payable allowed(user) {
        _removeAssetAndRepay(
            singularity,
            bingBang,
            user,
            removeShare,
            repayAmount,
            collateralShare,
            withdraw,
            withdrawData
        );
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
        _setApprovalForYieldBox(market, yieldBox);
        market.addCollateral(
            deposit ? address(this) : user,
            user,
            false,
            collateralAmount,
            _share
        );

        //borrow
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
        _setApprovalForYieldBox(market, yieldBox);
        market.repay(deposit ? address(this) : user, user, false, repayAmount);
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
            _setApprovalForYieldBox(bingBang, yieldBox);
            bingBang.addCollateral(
                address(this),
                user,
                false,
                collateralAmount,
                _share
            );
        }

        //borrow from BingBang
        bingBang.borrow(user, user, borrowAmount);

        //lend to Singularity
        uint256 assetId = singularity.assetId();
        uint256 borrowShare = yieldBox.toShare(assetId, borrowAmount, false);
        _setApprovalForYieldBox(singularity, yieldBox);
        singularity.addAsset(user, user, false, borrowShare);
    }

    function _depositAndAddAsset(
        IMarket singularity,
        address _user,
        uint256 _amount,
        bool deposit_,
        bool extractFromSender
    ) private {
        uint256 assetId = singularity.assetId();
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        (, address assetAddress, , ) = yieldBox.assets(assetId);

        uint256 _share = yieldBox.toShare(assetId, _amount, false);
        if (deposit_) {
            if (!extractFromSender) {
                _checkSender(_user);
            }
            //deposit into the yieldbox
            _extractTokens(
                extractFromSender ? msg.sender : _user,
                assetAddress,
                _amount
            );
            IERC20(assetAddress).approve(address(yieldBox), _amount);
            yieldBox.depositAsset(
                assetId,
                address(this),
                address(this),
                0,
                _share
            );
        }

        //add asset
        _setApprovalForYieldBox(singularity, yieldBox);
        singularity.addAsset(address(this), _user, false, _share);
    }

    function _removeAssetAndRepay(
        ISingularity singularity,
        IMarket bingBang,
        address user,
        uint256 removeShare, //slightly greater than _repayAmount to cover the interest
        uint256 repayAmount,
        uint256 collateralShare,
        bool withdraw,
        bytes calldata withdrawData
    ) private {
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        //remove asset
        uint256 bbAssetId = bingBang.assetId();
        uint256 _removeAmount = yieldBox.toAmount(
            bbAssetId,
            removeShare,
            false
        );
        singularity.removeAsset(user, address(this), removeShare);

        //repay
        uint256 repayed = bingBang.repay(
            address(this),
            user,
            false,
            repayAmount
        );
        if (repayed < _removeAmount) {
            yieldBox.transfer(
                address(this),
                user,
                bbAssetId,
                yieldBox.toShare(bbAssetId, _removeAmount - repayed, false)
            );
        }

        //remove collateral
        bingBang.removeCollateral(
            user,
            withdraw ? address(this) : user,
            collateralShare
        );

        //withdraw
        if (withdraw) {
            _withdraw(
                address(this),
                withdrawData,
                singularity,
                yieldBox,
                0,
                collateralShare,
                true
            );
        }
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

        require(
            yieldBox.toAmount(
                assetId,
                yieldBox.balanceOf(from, assetId),
                false
            ) >= amount,
            "SGL: not available"
        );

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
        (, uint16 destChain, bytes32 receiver, bytes memory adapterParams) = abi
            .decode(withdrawData, (bool, uint16, bytes32, bytes));

        uint256 gas = msg.value > 0 ? msg.value : address(this).balance;
        _withdrawTo(
            yieldBox,
            from,
            withdrawCollateral ? market.collateralId() : market.assetId(),
            destChain,
            receiver,
            amount,
            share,
            adapterParams,
            gas > 0 ? payable(msg.sender) : payable(this),
            gas
        );
    }

    function _setApprovalForYieldBox(
        IMarket market,
        IYieldBoxBase yieldBox
    ) private {
        bool isApproved = yieldBox.isApprovedForAll(
            address(this),
            address(market)
        );
        if (!isApproved) {
            yieldBox.setApprovalForAll(address(market), true);
        }
        isApproved = yieldBox.isApprovedForAll(address(this), address(market));
    }

    function _extractTokens(
        address _from,
        address _token,
        uint256 _amount
    ) private {
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
    }
}