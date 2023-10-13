// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IMarketLiquidatorReceiver {
    function onCollateralReceiver(
        address initiator,
        address tokenIn,
        address tokenOut,
        uint256 collateralAmount,
        bytes calldata data
    ) external returns (bool);
}
