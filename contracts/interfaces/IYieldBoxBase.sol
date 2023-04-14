// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IYieldBoxBase {
    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}
