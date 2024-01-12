// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

interface ICommonData {
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

    struct ISendOptions {
        uint256 extraGasLimit;
        address zroPaymentAddress;
    }

    struct IApproval {
        bool permitAll;
        bool allowFailure;
        bool yieldBoxTypeApproval;
        bool revokeYieldBox;
        uint16 actionType;
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
}
