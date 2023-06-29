// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ITapiocaOptionsBroker.sol";
import "./ITapiocaOptionLiquidityProvision.sol";
import {IUSDOBase} from "./IUSDO.sol";

interface IMagnetar {
    function getAmountForBorrowPart(
        address market,
        uint256 borrowPart
    ) external view returns (uint256 amount);

    function getBorrowPartForAmount(
        address market,
        uint256 amount
    ) external view returns (uint256 part);

    function withdrawTo(
        address yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        uint256 share,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas
    ) external payable;

    function depositRepayAndRemoveCollateral(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool extractFromSender,
        IUSDOBase.IWithdrawParams calldata withdrawCollateralParams
    ) external payable;

    function mintAndLend(
        address singularity,
        address bingBang,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool deposit,
        bool extractFromSender
    ) external payable;

    function depositAndAddAsset(
        address singularity,
        address user,
        uint256 amount,
        bool deposit,
        bool extractFromSender,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionsBroker.IOptionsParticipateData calldata participateData
    ) external payable;

    function removeAssetAndRepay(
        address user,
        IUSDOBase.IRemoveAndRepayExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData
    ) external payable;

    function depositAddCollateralAndBorrow(
        address market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        bool withdraw,
        bytes memory withdrawData
    ) external payable;
}
