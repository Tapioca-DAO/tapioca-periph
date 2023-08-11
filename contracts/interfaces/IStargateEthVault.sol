// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IStargateEthVault {
    function deposit() external payable;

    function withdraw(uint wad) external;
}
