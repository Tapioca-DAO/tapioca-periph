// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IMarketLiquidatorReceiver {
    function onCollateralReceiver(
        address initiator,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}
