// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ITapiocaOptionsBroker {
    function exerciseOption(
        uint256 _oTAPTokenID,
        address _paymentToken,
        uint256 _tapAmount
    ) external;
}