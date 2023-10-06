// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IPermitAction {
    function permitAction(bytes memory data, uint16 actionType) external;
}
