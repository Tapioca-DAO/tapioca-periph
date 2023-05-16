// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface INative {
    function deposit() external payable;

    function withdraw(uint256 _wad) external;

    function balanceOf(address _account) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}
