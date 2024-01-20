// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

interface ILiquidityBootstrappingPool {
    function getPoolId() external view returns (bytes32);
}
