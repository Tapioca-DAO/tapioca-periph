// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IUSDOBase {
    struct IWithdrawParams {
        bool withdraw;
        uint256 withdrawLzFeeAmount;
        bool withdrawOnOtherChain;
        uint16 withdrawLzChainId;
        bytes withdrawAdapterParams;
    }

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

    struct IRemoveParams {
        uint256 share;
        address marketHelper;
        address market;
    }

    struct ILendParams {
        bool repay;
        uint256 depositAmount;
        uint256 repayAmount;
        address marketHelper;
        address market;
        bool removeCollateral;
        uint256 removeCollateralShare;
    }

    struct ISendOptions {
        uint256 extraGasLimit;
        address zroPaymentAddress;
    }

    struct ILeverageLZData {
        uint256 srcExtraGasLimit;
        uint16 lzSrcChainId;
        uint16 lzDstChainId;
        address zroPaymentAddress;
        bytes dstAirdropAdapterParam;
        bytes srcAirdropAdapterParam;
        address refundAddress;
    }

    struct ILeverageSwapData {
        address tokenOut;
        uint256 amountOutMin;
        bytes data;
    }
    struct ILeverageExternalContractsData {
        address swapper;
        address magnetar;
        address tOft;
        address srcMarket;
    }

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function sendAndLendOrRepay(
        address _from,
        address _to,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        ILendParams calldata lendParams,
        IApproval[] calldata approvals,
        IWithdrawParams calldata withdrawParams,
        bytes calldata adapterParams
    ) external payable;

    function sendForLeverage(
        uint256 amount,
        address leverageFor,
        ILeverageLZData calldata lzData,
        ILeverageSwapData calldata swapData,
        ILeverageExternalContractsData calldata externalData
    ) external payable;

    function initMultiHopBuy(
        address from,
        uint256 collateralAmount,
        uint256 borrowAmount,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData,
        bytes calldata airdropAdapterParams,
        IUSDOBase.IApproval[] memory approvals
    ) external payable;
}

interface IUSDO is IUSDOBase, IERC20Metadata {}
