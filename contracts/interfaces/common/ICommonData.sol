// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

struct IWithdrawParams {
    bool withdraw;
    uint256 withdrawLzFeeAmount;
    bool withdrawOnOtherChain;
    uint16 withdrawLzChainId;
    bytes withdrawAdapterParams;
    bool unwrap; // valid only for TOFTs
    address payable refundAddress;
    address zroPaymentAddress;
}

struct ICommonExternalContracts {
    address magnetar;
    address singularity;
    address bigBang;
}

struct IDepositData {
    bool deposit;
    uint256 amount;
    bool extractFromSender;
}

interface ICommonData {}
