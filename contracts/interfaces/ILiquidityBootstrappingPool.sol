// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ILiquidityBootstrappingPool {
    function getPoolId() external view returns (bytes32);
}
