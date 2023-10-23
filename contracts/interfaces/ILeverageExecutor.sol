// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ILeverageExecutor {
    function getCollateral(
        uint256 assetId,
        uint256 collateralId,
        uint256 assetShareIn,
        address from,
        bytes calldata data
    ) external returns (uint256 collateralAmountOut); //used for buyCollateral

    function getAsset(
        uint256 assetId,
        uint256 collateralId,
        uint256 collateralShareIn,
        address from,
        bytes calldata data
    ) external returns (uint256 assetAmountOut); //used for sellCollateral
}
