// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

interface IStargatePool {
    function feeLibrary() external view returns (address);

    function token() external view returns (address);

    function totalLiquidity() external view returns (uint256);
}
