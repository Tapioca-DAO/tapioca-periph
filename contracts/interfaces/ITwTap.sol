// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

interface ITwTap {
    function rewardTokenIndex(address token) external view returns (uint256);

    function distributeReward(uint256 _rewardTokenId, uint256 _amount) external;
}
