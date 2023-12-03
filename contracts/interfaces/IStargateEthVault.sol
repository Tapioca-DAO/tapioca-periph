// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IStargateEthVault {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function balanceOf(address) external view returns (uint256);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) external returns (bool);
}
