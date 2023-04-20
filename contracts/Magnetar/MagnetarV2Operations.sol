// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "tapioca-sdk/dist/contracts/libraries/LzLib.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IBigBang.sol";
import "../interfaces/ISingularity.sol";
import "../interfaces/IYieldBoxBase.sol";

abstract contract MagnetarV2Operations {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

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

    function _depositAddCollateralAndBorrow(
        IMarket market,
        address _user,
        uint256 _collateralAmount,
        uint256 _borrowAmount,
        bool extractFromSender,
        bool deposit_,
        bool withdraw_,
        bytes memory _withdrawData
    ) internal {
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        uint256 collateralId = market.collateralId();

        (, address collateralAddress, , ) = yieldBox.assets(collateralId);

        //deposit into the yieldbox
        uint256 _share = yieldBox.toShare(
            collateralId,
            _collateralAmount,
            false
        );
        if (deposit_) {
            _extractTokens(
                extractFromSender ? msg.sender : _user,
                collateralAddress,
                _collateralAmount
            );
            IERC20(collateralAddress).approve(
                address(yieldBox),
                _collateralAmount
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
            deposit_ ? address(this) : _user,
            _user,
            false,
            _share
        );

        //borrow
        address borrowReceiver = withdraw_ ? address(this) : _user;
        market.borrow(_user, borrowReceiver, _borrowAmount);

        if (withdraw_) {
            _withdraw(
                borrowReceiver,
                _withdrawData,
                market,
                yieldBox,
                _borrowAmount,
                0,
                false
            );
        }
    }

    function _depositAndRepay(
        IMarket market,
        address _user,
        uint256 _depositAmount,
        uint256 _repayAmount,
        bool deposit_,
        bool extractFromSender
    ) internal {
        uint256 assetId = market.assetId();
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        (, address assetAddress, , ) = yieldBox.assets(assetId);

        //deposit into the yieldbox
        if (deposit_) {
            _extractTokens(
                extractFromSender ? msg.sender : _user,
                assetAddress,
                _depositAmount
            );
            IERC20(assetAddress).approve(address(yieldBox), _depositAmount);
            yieldBox.depositAsset(
                assetId,
                address(this),
                address(this),
                _depositAmount,
                0
            );
        }

        //repay
        _setApprovalForYieldBox(market, yieldBox);
        market.repay(
            deposit_ ? address(this) : _user,
            _user,
            false,
            _repayAmount
        );
    }

    function _depositRepayAndRemoveCollateral(
        IMarket market,
        address _user,
        uint256 _depositAmount,
        uint256 _repayAmount,
        uint256 _collateralAmount,
        bool deposit_,
        bool withdraw_,
        bool extractFromSender
    ) internal {
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        _depositAndRepay(
            market,
            _user,
            _depositAmount,
            _repayAmount,
            deposit_,
            extractFromSender
        );

        //remove collateral
        address receiver = withdraw_ ? address(this) : _user;
        uint256 collateralShare = yieldBox.toShare(
            market.collateralId(),
            _collateralAmount,
            false
        );
        market.removeCollateral(_user, receiver, collateralShare);

        //withdraw
        if (withdraw_) {
            yieldBox.withdraw(
                market.collateralId(),
                address(this),
                _user,
                _collateralAmount,
                0
            );
        }
    }

    function _mintAndLend(
        ISingularity singularity,
        IMarket bingBang,
        address _user,
        uint256 _collateralAmount,
        uint256 _borrowAmount,
        bool deposit_,
        bool extractFromSender
    ) internal {
        uint256 collateralId = bingBang.collateralId();
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        (, address collateralAddress, , ) = yieldBox.assets(collateralId);
        uint256 _share = yieldBox.toShare(
            collateralId,
            _collateralAmount,
            false
        );

        if (deposit_) {
            //deposit to YieldBox
            _extractTokens(
                extractFromSender ? msg.sender : _user,
                collateralAddress,
                _collateralAmount
            );
            IERC20(collateralAddress).approve(
                address(yieldBox),
                _collateralAmount
            );
            yieldBox.depositAsset(
                collateralId,
                address(this),
                address(this),
                0,
                _share
            );
        }

        if (_collateralAmount > 0) {
            //add collateral to BingBang
            _setApprovalForYieldBox(bingBang, yieldBox);
            bingBang.addCollateral(address(this), _user, false, _share);
        }

        //borrow from BingBang
        bingBang.borrow(_user, _user, _borrowAmount);

        //lend to Singularity
        uint256 assetId = singularity.assetId();
        uint256 borrowShare = yieldBox.toShare(assetId, _borrowAmount, false);
        _setApprovalForYieldBox(singularity, yieldBox);
        singularity.addAsset(_user, _user, false, borrowShare);
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
        uint256 _removeShare, //slightly greater than _repayAmount to cover the interest
        uint256 _repayAmount,
        uint256 _collateralShare,
        bool withdraw_,
        bytes calldata withdrawData_
    ) internal {
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        //remove asset
        uint256 bbAssetId = bingBang.assetId();
        uint256 _removeAmount = yieldBox.toAmount(
            bbAssetId,
            _removeShare,
            false
        );
        singularity.removeAsset(msg.sender, address(this), _removeShare);

        //repay
        uint256 repayed = bingBang.repay(
            address(this),
            msg.sender,
            false,
            _repayAmount
        );
        if (repayed < _removeAmount) {
            yieldBox.transfer(
                address(this),
                msg.sender,
                bbAssetId,
                yieldBox.toShare(bbAssetId, _removeAmount - repayed, false)
            );
        }

        //remove collateral
        bingBang.removeCollateral(
            msg.sender,
            withdraw_ ? address(this) : msg.sender,
            _collateralShare
        );

        //withdraw
        if (withdraw_) {
            _withdraw(
                address(this),
                withdrawData_,
                singularity,
                yieldBox,
                0,
                _collateralShare,
                true
            );
        }
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

    function _withdraw(
        address _from,
        bytes memory _withdrawData,
        IMarket market,
        IYieldBoxBase yieldBox,
        uint256 _amount,
        uint256 _share,
        bool _withdrawCollateral
    ) internal {
        bool _otherChain;
        uint16 _destChain;
        bytes32 _receiver;
        bytes memory _adapterParams;
        require(_withdrawData.length > 0, "MagnetarV2: withdrawData is empty");

        (_otherChain, _destChain, _receiver, _adapterParams) = abi.decode(
            _withdrawData,
            (bool, uint16, bytes32, bytes)
        );
        if (!_otherChain) {
            yieldBox.withdraw(
                _withdrawCollateral ? market.collateralId() : market.assetId(),
                address(this),
                LzLib.bytes32ToAddress(_receiver),
                _amount,
                _share
            );
            return;
        }

        market.withdrawTo{
            value: msg.value > 0 ? msg.value : address(this).balance
        }(
            _from,
            _destChain,
            _receiver,
            _amount,
            _adapterParams,
            msg.value > 0 ? payable(msg.sender) : payable(this)
        );
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
