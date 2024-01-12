// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

interface IPermitAll {
    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external; // available on YieldBoxPermit

    function revokeAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external; // available on YieldBoxPermit
}
