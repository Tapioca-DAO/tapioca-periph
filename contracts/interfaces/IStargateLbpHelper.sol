// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

interface IStargateLbpHelper {
    function _sgReceive(
        address token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external;
}
