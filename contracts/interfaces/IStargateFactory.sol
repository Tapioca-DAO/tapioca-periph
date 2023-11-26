// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IStargateFactory {
    function getPool(uint256 poolId) external view returns (address);
}
