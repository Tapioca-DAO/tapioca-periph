// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {ITapiocaOptionLiquidityProvision} from "contracts/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ITapiocaOptionBroker} from "contracts/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {IMagnetarHelper} from "contracts/interfaces/periph/IMagnetarHelper.sol";
import {ICommonData} from "contracts/interfaces/common/ICommonData.sol";
import {IUSDOBase} from "contracts/interfaces/bar/IUSDO.sol";

interface IMagnetar {
    function helper() external view returns (IMagnetarHelper);

    function withdrawToChain(
        address yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas,
        bool unwrap, //valid only for TOFT
        address zroPaymentAddress
    ) external payable;

    function mintFromBBAndLendOnSGL(
        address user,
        uint256 lendAmount,
        IUSDOBase.IMintData calldata mintData,
        ICommonData.IDepositData calldata depositData,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionBroker.IOptionsParticipateData calldata participateData,
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
