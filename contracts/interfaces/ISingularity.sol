// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IMarket.sol";
import {IUSDOBase} from "./IUSDO.sol";

interface ISingularity is IMarket {
    struct AccrueInfo {
        uint64 interestPerSecond;
        uint64 lastAccrued;
        uint128 feesEarnedFraction;
    }

    function accrueInfo()
        external
        view
        returns (
            uint64 interestPerSecond,
            uint64 lastBlockAccrued,
            uint128 feesEarnedFraction
        );

    function totalAsset() external view returns (uint128 elastic, uint128 base);

    function removeAsset(
        address from,
        address to,
        uint256 fraction
    ) external returns (uint256 share);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function liquidationQueue() external view returns (address payable);

    function computeAllowedLendShare(
        uint256 amount,
        uint256 tokenId
    ) external view returns (uint256 share);

    function getInterestDetails()
        external
        view
        returns (AccrueInfo memory _accrueInfo, uint256 utilization);
    
    function minimumTargetUtilization() external view returns (uint256);

    function maximumTargetUtilization() external view returns (uint256);

    function minimumInterestPerSecond() external view returns (uint256);

    function maximumInterestPerSecond() external view returns (uint256);

    function interestElasticity() external view returns (uint256);
    
    function startingInterestPerSecond() external view returns (uint256);

    function multiHopBuyCollateral(
        address from,
        uint256 collateralAmount,
        uint256 borrowAmount,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData
    ) external payable;

    function multiHopSellCollateral(
        address from,
        uint256 share,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData
    ) external payable;
}
