// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}
