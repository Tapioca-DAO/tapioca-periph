// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @dev interface for TAP token
interface ITapOFT {
    function extractTAP(address to, uint256 value) external;

    function approve(address to, uint256 value) external;

    function balanceOf(address user) external view returns (uint256);

    function emissionsStartTime() external view returns (uint256);

    function mintedInWeek(int256 week) external view returns (uint256);
}
