// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ISendFrom.sol";

interface ITOFT {
    // Structs
    struct ITOFTSendOptions {
        uint256 extraGasLimit;
        address zroPaymentAddress;
        bool wrap;
    }
    struct IUSDOSendOptions {
        uint256 extraGasLimit;
        address zroPaymentAddress;
        bool strategyDeposit;
    }
    struct ITOFTApproval {
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
    struct IUSDOApproval {
        bool allowFailure;
        address target;
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct IWithdrawParams {
        uint256 withdrawLzFeeAmount;
        bool withdrawOnOtherChain;
        uint16 withdrawLzChainId;
        bytes withdrawAdapterParams;
    }
    struct IBorrowParams {
        uint256 amount;
        uint256 borrowAmount;
        address marketHelper;
        address market;
    }
    struct ILendParams {
        uint256 amount;
        address marketHelper;
        address market;
    }

    // Functions
    function wrap(
        address fromAddress,
        address toAddress,
        uint256 amount
    ) external;

    function wrapNative(address _toAddress) external payable;

    function sendToYBAndBorrow(
        address _from,
        address _to,
        uint16 lzDstChainId,
        bytes calldata airdropAdapterParams,
        IBorrowParams calldata borrowParams,
        IWithdrawParams calldata withdrawParams,
        ITOFTSendOptions calldata options,
        ITOFTApproval[] calldata approvals
    ) external payable;

    function sendToYBAndLend(
        address _from,
        address _to,
        uint16 lzDstChainId,
        ILendParams calldata lendParams,
        IUSDOSendOptions calldata options,
        IUSDOApproval[] calldata approvals
    ) external payable;

    function sendToYB(
        address from,
        address to,
        uint256 amount,
        uint256 assetId,
        uint16 lzDstChainId,
        ITOFTSendOptions calldata options
    ) external payable;

    function sendToYB(
        address from,
        address to,
        uint256 amount,
        uint256 assetId,
        uint16 lzDstChainId,
        IUSDOSendOptions calldata options
    ) external payable;

    function retrieveFromYB(
        address from,
        uint256 amount,
        uint256 assetId,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        bytes memory airdropAdapterParam,
        bool strategyWithdrawal
    ) external payable;

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        ISendFrom.LzCallParams calldata _callParams
    ) external payable;
}
