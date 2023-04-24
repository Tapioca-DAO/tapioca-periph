// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "tapioca-sdk/dist/contracts/libraries/LzLib.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IBigBang.sol";
import "../interfaces/ISingularity.sol";
import "../interfaces/IYieldBoxBase.sol";
import "../interfaces/ISendFrom.sol";

abstract contract MagnetarV2Operations {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    /// *** VARS ***
    /// ***  ***
    struct MarketInfo {
        address collateral;
        uint256 collateralId;
        address asset;
        uint256 assetId;
        IOracle oracle;
        bytes oracleData;
        uint256 totalCollateralShare;
        uint256 userCollateralShare;
        Rebase totalBorrow;
        uint256 userBorrowPart;
        uint256 currentExchangeRate;
        uint256 spotExchangeRate;
        uint256 oracleExchangeRate;
        uint256 totalBorrowCap;
    }
    struct SingularityInfo {
        MarketInfo market;
        Rebase totalAsset;
        uint256 userAssetFraction;
        ISingularity.AccrueInfo accrueInfo;
    }
    struct BigBangInfo {
        MarketInfo market;
        IBigBang.AccrueInfo accrueInfo;
    }

    /// *** VIEW METHODS ***
    /// ***  ***
    function _singularityMarketInfo(
        address who,
        ISingularity[] memory markets
    ) internal view returns (SingularityInfo[] memory) {
        uint256 len = markets.length;
        SingularityInfo[] memory result = new SingularityInfo[](len);

        Rebase memory _totalAsset;
        ISingularity.AccrueInfo memory _accrueInfo;
        for (uint256 i = 0; i < len; i++) {
            ISingularity sgl = markets[i];

            result[i].market = _commonInfo(who, IMarket(address(sgl)));

            (uint128 totalAssetElastic, uint128 totalAssetBase) = sgl //
                .totalAsset(); //
            _totalAsset = Rebase(totalAssetElastic, totalAssetBase); //
            result[i].totalAsset = _totalAsset; //
            result[i].userAssetFraction = sgl.balanceOf(who); //

            (
                uint64 interestPerSecond,
                uint64 lastBlockAccrued,
                uint128 feesEarnedFraction
            ) = sgl.accrueInfo();
            _accrueInfo = ISingularity.AccrueInfo(
                interestPerSecond,
                lastBlockAccrued,
                feesEarnedFraction
            );
            result[i].accrueInfo = _accrueInfo;
        }

        return result;
    }

    function _bigBangMarketInfo(
        address who,
        IBigBang[] memory markets
    ) internal view returns (BigBangInfo[] memory) {
        uint256 len = markets.length;
        BigBangInfo[] memory result = new BigBangInfo[](len);

        IBigBang.AccrueInfo memory _accrueInfo;
        for (uint256 i = 0; i < len; i++) {
            IBigBang bigBang = markets[i];
            result[i].market = _commonInfo(who, IMarket(address(bigBang)));

            (uint64 debtRate, uint64 lastAccrued) = bigBang.accrueInfo();
            _accrueInfo = IBigBang.AccrueInfo(debtRate, lastAccrued);
            result[i].accrueInfo = _accrueInfo;
        }

        return result;
    }

    /// *** INTERNAL METHODS ***
    /// ***  ***
    function _depositAddCollateralAndBorrow(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        bool withdraw,
        bytes memory withdrawData
    ) internal {
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
    ) internal {
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
    ) internal {
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
    ) internal {
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
            bingBang.addCollateral(address(this), user, false, _share);
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
    ) internal {
        uint256 assetId = singularity.assetId();
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        (, address assetAddress, , ) = yieldBox.assets(assetId);

        uint256 _share = yieldBox.toShare(assetId, _amount, false);
        if (deposit_) {
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
    ) internal {
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
    ) internal {
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

    /// *** HELPER METHODS ***
    /// ***  ***

    function _withdraw(
        address from,
        bytes memory withdrawData,
        IMarket market,
        IYieldBoxBase yieldBox,
        uint256 amount,
        uint256 share,
        bool withdrawCollateral
    ) internal {
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
    ) internal {
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
    ) internal {
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
    }

    function _commonInfo(
        address who,
        IMarket market
    ) private view returns (MarketInfo memory) {
        Rebase memory _totalBorrowed;
        MarketInfo memory info;

        info.collateral = market.collateral();
        info.asset = market.asset();
        info.oracle = market.oracle();
        info.oracleData = market.oracleData();
        info.totalCollateralShare = market.totalCollateralShare();
        info.userCollateralShare = market.userCollateralShare(who);

        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);
        info.totalBorrow = _totalBorrowed;
        info.userBorrowPart = market.userBorrowPart(who);

        info.currentExchangeRate = market.exchangeRate();
        (, info.oracleExchangeRate) = market.oracle().peek(market.oracleData());
        info.spotExchangeRate = market.oracle().peekSpot(market.oracleData());
        info.totalBorrowCap = market.totalBorrowCap();
        info.assetId = market.assetId();
        info.collateralId = market.collateralId();
        return info;
    }

    receive() external payable virtual {}
}
