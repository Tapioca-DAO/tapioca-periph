// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function get_virtual_price() external view returns (uint256);

    function gamma() external view returns (uint256);

    function A() external view returns (uint256);
}
