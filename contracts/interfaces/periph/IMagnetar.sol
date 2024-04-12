// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {IOptionsLockData} from "../tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ICommonExternalContracts, IDepositData} from "../common/ICommonData.sol";
import {IOptionsParticipateData} from "../tap-token/ITapiocaOptionBroker.sol";
import {LZSendParam} from "../periph/ITapiocaOmnichainEngine.sol";
import {IRemoveAndRepay, IMintData} from "../oft/IUsdo.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

struct MagnetarWithdrawData {
    address yieldBox;
    uint256 assetId;
    bool unwrap;
    //@dev LZv2 send params
    LZSendParam lzSendParams;
    uint128 sendGas;
    uint128 composeGas;
    uint128 sendVal;
    uint128 composeVal;
    bytes composeMsg;
    uint16 composeMsgType;
    //@dev actions data
    bool withdraw;
}

/**
 * @dev MagnetarYieldBoxModule `depositAsset` calldata
 */
struct YieldBoxDepositData {
    address yieldbox;
    uint256 assetId;
    address from;
    address to;
    uint256 amount;
    uint256 share;
}

/**
 * @dev `exitPositionAndRemoveCollateral` calldata
 */
struct ExitPositionAndRemoveCollateralData {
    address user;
    ICommonExternalContracts externalData;
    IRemoveAndRepay removeAndRepayData;
}

/**
 * @dev `depositRepayAndRemoveCollateralFromMarket` calldata
 */
struct DepositRepayAndRemoveCollateralFromMarketData {
    address market;
    address marketHelper;
    address user;
    uint256 depositAmount;
    uint256 repayAmount;
    uint256 collateralAmount;
    MagnetarWithdrawData withdrawCollateralParams;
}

/**
 * @dev `depositAddCollateralAndBorrowFromMarket` calldata
 */
struct DepositAddCollateralAndBorrowFromMarketData {
    address market;
    address marketHelper;
    address user;
    uint256 collateralAmount;
    uint256 borrowAmount;
    bool deposit;
    MagnetarWithdrawData withdrawParams;
}

/**
 * @dev `mintBBLendSGLLockTOLP` calldata
 */
struct MintFromBBAndLendOnSGLData {
    address user;
    uint256 lendAmount;
    IMintData mintData;
    IDepositData depositData;
    IOptionsLockData lockData;
    IOptionsParticipateData participateData;
    ICommonExternalContracts externalContracts;
}

/**
 * @dev `crossChainMintFromBBAndLendOnSGL` calldata for step 1
 *  step 1: magnetar.mintBBLendXChainSGL (chain A) -->
 *         step 2: IUsdo compose call calls magnetar.depositLendAndSendForLocking (chain B) -->
 *              step 3: IToft(sglReceipt) compose call calls magnetar.lockAndParticipate (chain X)
 */
struct CrossChainMintFromBBAndLendOnSGLData {
    address user;
    address bigBang;
    address magnetar;
    address marketHelper;
    IMintData mintData;
    LendOrLockSendParams lendSendParams;
}

/**
 * @dev `crossChainMintFromBBAndLendOnSGL` calldata for step 2
 *  step 1: magnetar.mintBBLendXChainSGL (chain A) -->
 *         step 2: IUsdo compose call calls magnetar.depositLendAndSendForLocking (chain B) -->
 *              step 3: IToft(sglReceipt) compose call calls magnetar.lockAndParticipate (chain X)
 */
struct DepositAndSendForLockingData {
    address user;
    address singularity;
    address magnetar;
    uint256 assetId; // Singularity receipt token id
    uint256 lendAmount;
    IDepositData depositData;
    LendOrLockSendParams lockAndParticipateSendParams;
}

/**
 * @dev `crossChainMintFromBBAndLendOnSGL` calldata for step 3
 *  step 1: magnetar.mintBBLendXChainSGL (chain A) -->
 *         step 2: IUsdo compose call calls magnetar.depositLendAndSendForLocking (chain B) -->
 *              step 3: IToft(sglReceipt) compose call calls magnetar.lockAndParticipate (chain X)
 */
struct LockAndParticipateData {
    address user;
    address singularity;
    address magnetar;
    uint256 fraction;
    IOptionsLockData lockData;
    IOptionsParticipateData participateData;
}

struct LendOrLockSendParams {
    LZSendParam lzParams;
    uint128 lzSendGas;
    uint128 lzSendVal;
    uint128 lzComposeGas;
    uint128 lzComposeVal;
    uint16 lzComposeMsgType;
}

struct MagnetarCall {
    MagnetarAction id;
    address target;
    uint256 value;
    bool allowFailure;
    bytes call;
}

enum MagnetarAction {
    Permit, // 0 Permit singular operations.
    Wrap, // 1 Wrap/unwrap singular operations.
    Market, // 2 Market singular operations.
    TapLock, // 3 TapLock singular operations.
    OFT, // 4 LZ OFT singular operations.
    AssetModule, // 5  Usdo Singular operations.
    AssetXChainModule, // 6  Usdo Singular operations.
    CollateralModule, // 7 Collateral Singular related operations.
    MintModule, // 8 BigBang Singular related operations.
    MintXChainModule, // 9 BigBang Singular related operations.
    OptionModule, // 10 Market Module related operations.
    YieldBoxModule // 11 YieldBox module related operations.

}

enum MagnetarModule {
    AssetModule,
    AssetXChainModule,
    CollateralModule,
    MintModule,
    MintXChainModule,
    OptionModule,
    YieldBoxModule
}

// TODO: fill
interface IMagnetar {
    function burst(MagnetarCall[] calldata calls) external payable;

    function cluster() external view returns (address);

    function helper() external view returns (address);
}

interface IMagnetarModuleExtender {
    function isValidActionId(uint8 actionId) external view returns (bool);
    function handleAction(MagnetarCall calldata call) external payable;
}
