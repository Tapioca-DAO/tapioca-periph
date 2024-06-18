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
    address receiver;
    uint256 amount;
    bool unwrap;
    bool withdraw;
    bool extractFromSender;
}

/**
 * @dev MagnetarYieldBoxModule `depositAsset` calldata
 */
struct YieldBoxDepositData {
    address yieldBox;
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

struct LockAndParticipateData {
    address user;
    address tSglToken;
    address yieldBox;
    address magnetar;
    IOptionsLockData lockData;
    IOptionsParticipateData participateData;
    uint256 value;
}

struct MagnetarCall {
    uint8 id;
    address target;
    uint256 value;
    bytes call;
}

enum MagnetarAction {
    // Simple operations
    Permit, // 0 Permit singular operations.
    Wrap, // 1 Wrap/unwrap singular operations.
    Market, // 2 Market singular operations.
    TapLock, // 3 TapLock singular operations.
    TapUnlock, // 4 TapLock singular operations.
    OFT, // 5 LZ OFT singular operations.
    ExerciseOption, // 6 tOB singular operation
    // Complex operations
    CollateralModule, // 7 Collateral Singular related operations.
    MintModule, // 8 BigBang Singular related operations.
    OptionModule, // 9 Market Module related operations.
    YieldBoxModule // 10 YieldBox module related operations.

}

enum MagnetarModule {
    CollateralModule,
    MintModule,
    OptionModule,
    YieldBoxModule
}

interface IMagnetar {
    function burst(MagnetarCall[] calldata calls) external payable;
    function cluster() external view returns (address);
    function helper() external view returns (address);
}

interface IMagnetarModuleExtender {
    function isValidActionId(uint8 actionId) external view returns (bool);
    function handleAction(MagnetarCall calldata call) external payable;
}
