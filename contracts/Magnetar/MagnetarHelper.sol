// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "../interfaces/ISingularity.sol";
import "../interfaces/IBigBang.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IYieldBoxBase.sol";
import "../interfaces/IPenrose.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/enums/YieldBoxTokenType.sol";
import {IUSDOBase} from "../interfaces/IUSDO.sol";

contract MagnetarHelper {
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
        uint256 totalYieldBoxCollateralShare;
        uint256 totalYieldBoxCollateralAmount;
        uint256 totalYieldBoxAssetShare;
        uint256 totalYieldBoxAssetAmount;
        TokenType yieldBoxCollateralTokenType;
        address yieldBoxCollateralContractAddress;
        address yieldBoxCollateralStrategyAddress;
        uint256 yieldBoxCollateralTokenId;
        TokenType yieldBoxAssetTokenType;
        address yieldBoxAssetContractAddress;
        address yieldBoxAssetStrategyAddress;
        uint256 yieldBoxAssetTokenId;
        uint256 collateralizationRate;
    }

    struct SingularityInfo {
        MarketInfo market;
        Rebase totalAsset;
        uint256 userAssetFraction;
        ISingularity.AccrueInfo accrueInfo;
        uint256 utilization;
        uint256 minimumTargetUtilization;
        uint256 maximumTargetUtilization;
        uint256 minimumInterestPerSecond;
        uint256 maximumInterestPerSecond;
        uint256 interestElasticity;
        uint256 startingInterestPerSecond;
    }

    struct BigBangInfo {
        MarketInfo market;
        IBigBang.AccrueInfo accrueInfo;
        uint256 minDebtRate;
        uint256 maxDebtRate;
        uint256 debtRateAgainstEthMarket;
        address mainBBMarket;
        uint256 mainBBDebtRate;
        uint256 currentDebtRate;
    }

    // ******************** //
    // *** VIEW METHODS *** //
    // ******************** //
    /// @notice returns Singularity markets' information
    /// @param who user to return for
    /// @param markets the list of Singularity markets to query for
    function singularityMarketInfo(address who, ISingularity[] calldata markets)
        external
        view
        returns (SingularityInfo[] memory)
    {
        return _singularityMarketInfo(who, markets);
    }

    /// @notice returns BigBang markets' information
    /// @param who user to return for
    /// @param markets the list of BigBang markets to query for
    function bigBangMarketInfo(address who, IBigBang[] calldata markets) external view returns (BigBangInfo[] memory) {
        return _bigBangMarketInfo(who, markets);
    }

    /// @notice Calculate the collateral amount off the shares.
    /// @param market the Singularity or BigBang address
    /// @param share The shares.
    /// @return amount The amount.
    function getCollateralAmountForShare(IMarket market, uint256 share) external view returns (uint256 amount) {
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());
        return yieldBox.toAmount(market.collateralId(), share, false);
    }

    /// @notice Calculate the collateral shares that are needed for `borrowPart`,
    /// taking the current exchange rate into account.
    /// @param market the Singularity or BigBang address
    /// @param borrowPart The borrow part.
    /// @return collateralShares The collateral shares.
    function getCollateralSharesForBorrowPart(
        IMarket market,
        uint256 borrowPart,
        uint256 collateralizationRatePrecision,
        uint256 exchangeRatePrecision
    ) external view returns (uint256 collateralShares) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market.totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());
        uint256 borrowAmount = _totalBorrowed.toElastic(borrowPart, false);

        uint256 val = (borrowAmount * collateralizationRatePrecision * market.exchangeRate())
            / (market.collateralizationRate() * exchangeRatePrecision);
        return yieldBox.toShare(market.collateralId(), val, false);
    }

    /// @notice Return the equivalent of borrow part in asset amount.
    /// @param market the Singularity or BigBang address
    /// @param borrowPart The amount of borrow part to convert.
    /// @return amount The equivalent of borrow part in asset amount.
    function getAmountForBorrowPart(IMarket market, uint256 borrowPart) external view returns (uint256 amount) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market.totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        return _totalBorrowed.toElastic(borrowPart, false);
    }

    /// @notice Return the equivalent of amount in borrow part.
    /// @param market the Singularity or BigBang address
    /// @param amount The amount to convert.
    /// @return part The equivalent of amount in borrow part.
    function getBorrowPartForAmount(IMarket market, uint256 amount) external view returns (uint256 part) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market.totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        return _totalBorrowed.toBase(amount, false);
    }

    /// @notice Compute the amount of `singularity.assetId` from `fraction`
    /// `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`
    /// @param singularity the singularity address
    /// @param fraction The fraction.
    /// @return amount The amount.
    function getAmountForAssetFraction(ISingularity singularity, uint256 fraction)
        external
        view
        returns (uint256 amount)
    {
        (uint128 totalAssetElastic, uint128 totalAssetBase) = singularity.totalAsset();
        (uint128 totalBorrowElastic,) = singularity.totalBorrow();

        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        uint256 allShare = totalAssetElastic + yieldBox.toShare(singularity.assetId(), totalBorrowElastic, true);

        return yieldBox.toAmount(singularity.assetId(), (fraction * allShare) / totalAssetBase, false);
    }

    /// @notice Compute the fraction of `singularity.assetId` from `amount`
    /// `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`
    /// @param singularity the singularity address
    /// @param amount The amount.
    /// @return fraction The fraction.
    function getFractionForAmount(ISingularity singularity, uint256 amount) external view returns (uint256 fraction) {
        (uint128 totalAssetShare, uint128 totalAssetBase) = singularity.totalAsset();
        (uint128 totalBorrowElastic,) = singularity.totalBorrow();
        uint256 assetId = singularity.assetId();

        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        uint256 share = yieldBox.toShare(assetId, amount, false);
        uint256 allShare = totalAssetShare + yieldBox.toShare(assetId, totalBorrowElastic, true);

        fraction = allShare == 0 ? share : (share * totalAssetBase) / allShare;
    }

    function _singularityMarketInfo(address who, ISingularity[] memory markets)
        private
        view
        returns (SingularityInfo[] memory)
    {
        uint256 len = markets.length;
        SingularityInfo[] memory result = new SingularityInfo[](len);

        Rebase memory _totalAsset;
        for (uint256 i; i < len; i++) {
            ISingularity sgl = markets[i];

            result[i].market = _commonInfo(who, IMarket(address(sgl)));

            (uint128 totalAssetElastic, uint128 totalAssetBase) = sgl //
                .totalAsset();
            //
            _totalAsset = Rebase(totalAssetElastic, totalAssetBase);
            //
            result[i].totalAsset = _totalAsset;
            //
            result[i].userAssetFraction = sgl.balanceOf(who);
            //
            (ISingularity.AccrueInfo memory _accrueInfo, uint256 _utilization) = sgl.getInterestDetails();

            result[i].accrueInfo = _accrueInfo;
            result[i].utilization = _utilization;
            result[i].minimumTargetUtilization = sgl.minimumTargetUtilization();
            result[i].maximumTargetUtilization = sgl.maximumTargetUtilization();
            result[i].minimumInterestPerSecond = sgl.minimumInterestPerSecond();
            result[i].maximumInterestPerSecond = sgl.maximumInterestPerSecond();
            result[i].interestElasticity = sgl.interestElasticity();
            result[i].startingInterestPerSecond = sgl.startingInterestPerSecond();
        }

        return result;
    }

    function _bigBangMarketInfo(address who, IBigBang[] memory markets) private view returns (BigBangInfo[] memory) {
        uint256 len = markets.length;
        BigBangInfo[] memory result = new BigBangInfo[](len);

        IBigBang.AccrueInfo memory _accrueInfo;
        for (uint256 i; i < len; i++) {
            IBigBang bigBang = markets[i];
            result[i].market = _commonInfo(who, IMarket(address(bigBang)));

            (uint64 debtRate, uint64 lastAccrued) = bigBang.accrueInfo();
            _accrueInfo = IBigBang.AccrueInfo(debtRate, lastAccrued);
            result[i].accrueInfo = _accrueInfo;
            result[i].minDebtRate = bigBang.minDebtRate();
            result[i].maxDebtRate = bigBang.maxDebtRate();
            result[i].debtRateAgainstEthMarket = bigBang.debtRateAgainstEthMarket();
            result[i].currentDebtRate = bigBang.getDebtRate();

            IPenrose penrose = IPenrose(bigBang.penrose());
            result[i].mainBBMarket = penrose.bigBangEthMarket();
            result[i].mainBBDebtRate = penrose.bigBangEthDebtRate();
        }

        return result;
    }

    function _commonInfo(address who, IMarket market) private view returns (MarketInfo memory) {
        Rebase memory _totalBorrowed;
        MarketInfo memory info;

        info.collateral = market.collateral();
        info.asset = market.asset();
        info.oracle = IOracle(market.oracle());
        info.oracleData = market.oracleData();
        info.totalCollateralShare = market.totalCollateralShare();
        info.userCollateralShare = market.userCollateralShare(who);

        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market.totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);
        info.totalBorrow = _totalBorrowed;
        info.userBorrowPart = market.userBorrowPart(who);

        info.currentExchangeRate = market.exchangeRate();
        (, info.oracleExchangeRate) = IOracle(market.oracle()).peek(market.oracleData());
        info.spotExchangeRate = IOracle(market.oracle()).peekSpot(market.oracleData());
        info.totalBorrowCap = market.totalBorrowCap();
        info.assetId = market.assetId();
        info.collateralId = market.collateralId();
        info.collateralizationRate = market.collateralizationRate();

        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        (info.totalYieldBoxCollateralShare, info.totalYieldBoxCollateralAmount) =
            yieldBox.assetTotals(info.collateralId);
        (info.totalYieldBoxAssetShare, info.totalYieldBoxAssetAmount) = yieldBox.assetTotals(info.assetId);

        (
            info.yieldBoxCollateralTokenType,
            info.yieldBoxCollateralContractAddress,
            info.yieldBoxCollateralStrategyAddress,
            info.yieldBoxCollateralTokenId
        ) = yieldBox.assets(info.collateralId);
        (
            info.yieldBoxAssetTokenType,
            info.yieldBoxAssetContractAddress,
            info.yieldBoxAssetStrategyAddress,
            info.yieldBoxAssetTokenId
        ) = yieldBox.assets(info.assetId);

        return info;
    }
}
