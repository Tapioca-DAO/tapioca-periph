// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ITapiocaOptionsBrokerCrossChain {
    struct IApproval {
        bool permitAll;
        bool allowFailure;
        address target;
        bool permitBorrow;
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct IExerciseOptionsData {
        address from;
        address target;
        uint256 paymentTokenAmount;
        uint256 oTAPTokenID;
        address paymentToken;
        uint256 tapAmount;
    }
    struct IExerciseLZData {
        uint16 lzDstChainId;
        address zroPaymentAddress;
        uint256 extraGas;

    }

    function exerciseOption(
        address from,
        uint256 paymentTokenAmount,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        uint256 extraGas,
        address target,
        uint256 oTAPTokenID,
        address paymentToken,
        uint256 tapAmount,
        IApproval[] memory approvals
    ) external payable;
}

interface ITapiocaOptionsBroker {
    function exerciseOption(
        uint256 _oTAPTokenID,
        address _paymentToken,
        uint256 _tapAmount
    ) external;
}
