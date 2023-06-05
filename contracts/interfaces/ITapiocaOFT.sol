// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ISendFrom.sol";
import {IUSDOBase} from "./IUSDO.sol";

interface ITapiocaOFTBase {
    function hostChainID() external view returns (uint256);

    function wrap(
        address fromAddress,
        address toAddress,
        uint256 amount
    ) external;

    function wrapNative(address _toAddress) external payable;

    function unwrap(address _toAddress, uint256 _amount) external;

    function erc20() external view returns (address);
}

/// @dev used for generic TOFTs
interface ITapiocaOFT is ISendFrom, ITapiocaOFTBase {
    struct ISendOptions {
        uint256 extraGasLimit;
        address zroPaymentAddress;
    }

    struct IApproval {
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

    function totalFees() external view returns (uint256);

    function erc20() external view returns (address);

    function wrappedAmount(uint256 _amount) external view returns (uint256);

    function isHostChain() external view returns (bool);

    function balanceOf(address _holder) external view returns (uint256);

    function isTrustedRemote(
        uint16 lzChainId,
        bytes calldata path
    ) external view returns (bool);

    function getLzChainId() external view returns (uint16);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function extractUnderlying(uint256 _amount) external;

    function harvestFees() external;

    /// OFT specific methods
    function sendToYBAndBorrow(
        address _from,
        address _to,
        uint16 lzDstChainId,
        bytes calldata airdropAdapterParams,
        IBorrowParams calldata borrowParams,
        IWithdrawParams calldata withdrawParams,
        ISendOptions calldata options,
        IApproval[] calldata approvals
    ) external payable;

    function sendToStrategy(
        address _from,
        address _to,
        uint256 amount,
        uint256 share,
        uint256 assetId,
        uint16 lzDstChainId,
        ISendOptions calldata options
    ) external payable;

    function retrieveFromStrategy(
        address _from,
        uint256 amount,
        uint256 share,
        uint256 assetId,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        bytes memory airdropAdapterParam
    ) external payable;

    function sendForLeverage(
        uint256 amount,
        address leverageFor,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData
    ) external payable;
}
