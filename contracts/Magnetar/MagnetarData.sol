// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../interfaces/ISendFrom.sol";
import "../interfaces/ITOFT.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IMarketHelper.sol";
import "../interfaces/IYieldBoxBase.sol";

abstract contract MagnetarData {
    uint16 internal constant PERMIT_ALL = 1;
    uint16 internal constant PERMIT = 2;
    uint16 internal constant YB_DEPOSIT_ASSET = 3;
    uint16 internal constant YB_WITHDRAW_ASSET = 4;
    uint16 internal constant SGL_ADD_COLLATERAL = 5;
    uint16 internal constant SGL_BORROW = 6;
    uint16 internal constant SGL_WITHDRAW_TO = 7;
    uint16 internal constant SGL_LEND = 8;
    uint16 internal constant SGL_REPAY = 9;
    uint16 internal constant TOFT_WRAP = 10;
    uint16 internal constant TOFT_SEND_FROM = 11;
    uint16 internal constant TOFT_SEND_APPROVAL = 12;
    uint16 internal constant TOFT_SEND_AND_BORROW = 13;
    uint16 internal constant TOFT_SEND_AND_LEND = 14;
    uint16 internal constant TOFT_SEND_YB = 15;
    uint16 internal constant TOFT_RETRIEVE_YB = 16;
    uint16 internal constant HELPER_LEND = 17;
    uint16 internal constant HELPER_BORROW = 18;

    struct Call {
        uint16 id;
        address target;
        uint256 value;
        bool allowFailure;
        bytes call;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    // Actions data
    struct PermitData {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PermitAllData {
        address owner;
        address spender;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct WrapData {
        address from;
        address to;
        uint256 amount;
    }

    struct WrapNativeData {
        address to;
    }

    struct TOFTSendAndBorrowData {
        address from;
        address to;
        uint16 lzDstChainId;
        bytes airdropAdapterParams;
        ITOFT.IBorrowParams borrowParams;
        ITOFT.IWithdrawParams withdrawParams;
        ITOFT.ITOFTSendOptions options;
        ITOFT.ITOFTApproval[] approvals;
    }

    struct TOFTSendAndLendData {
        address from;
        address to;
        uint16 lzDstChainId;
        ITOFT.ILendParams lendParams;
        ITOFT.IUSDOSendOptions options;
        ITOFT.IUSDOApproval[] approvals;
    }

    struct TOFTSendToYBData {
        address from;
        address to;
        uint256 amount;
        uint256 assetId;
        uint16 lzDstChainId;
        ITOFT.ITOFTSendOptions options;
    }
    struct USDOSendToYBData {
        address from;
        address to;
        uint256 amount;
        uint256 assetId;
        uint16 lzDstChainId;
        ITOFT.IUSDOSendOptions options;
    }

    struct YieldBoxDepositData {
        uint256 assetId;
        address from;
        address to;
        uint256 amount;
        uint256 share;
    }

    struct SGLAddCollateralData {
        address from;
        address to;
        bool skim;
        uint256 share;
    }

    struct SGLBorrowData {
        address from;
        address to;
        uint256 amount;
    }

    struct SGLLendData {
        address from;
        address to;
        bool skim;
        uint256 share;
    }

    struct SGLRepayData {
        address from;
        address to;
        bool skim;
        uint256 part;
    }

    struct HelperLendData {
        address market;
        address from;
        uint256 amount;
        bool deposit;
        bool extractFromSender;
    }

    struct HelperBorrowData {
        address market;
        address user;
        uint256 collateralAmount;
        uint256 borrowAmount;
        bool extractFromSender;
        bool deposit;
        bool withdraw;
        bytes withdrawData;
    }
}
