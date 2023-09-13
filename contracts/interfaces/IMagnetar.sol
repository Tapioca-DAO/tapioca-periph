// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ITapiocaOptionsBroker.sol";
import "./ITapiocaOptionLiquidityProvision.sol";
import "./ICommonData.sol";
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

    function withdrawToChain(
        address yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas
    ) external payable;

    function mintFromBBAndLendOnSGL(
        address user,
        uint256 lendAmount,
        IUSDOBase.IMintData calldata mintData,
        ICommonData.IDepositData calldata depositData,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionsBroker.IOptionsParticipateData calldata participateData,
        ICommonData.ICommonExternalContracts calldata externalContracts
    ) external payable;

    function depositRepayAndRemoveCollateralFromMarket(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool extractFromSender,
        ICommonData.IWithdrawParams calldata withdrawCollateralParams
    ) external payable;

    function exitPositionAndRemoveCollateral(
        address user,
        ICommonData.ICommonExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData
    ) external payable;

    function depositAddCollateralAndBorrowFromMarket(
        address market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        ICommonData.IWithdrawParams memory withdrawParams
    ) external payable;
}
