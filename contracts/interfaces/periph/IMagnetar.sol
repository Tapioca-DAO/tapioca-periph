// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ICommonExternalContracts, IDepositData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {LZSendParam} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {IRemoveAndRepay} from "tapioca-periph/interfaces/bar/IUSDO.sol";
import {IMintData} from "tapioca-periph/interfaces/bar/IUSDO.sol";

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
    address user;
    uint256 collateralAmount;
    uint256 borrowAmount;
    bool deposit;
    MagnetarWithdrawData withdrawParams;
}

/**
 * @dev `mintFromBBAndLendOnSGL` calldata
 */
struct MintFromBBAndLendOnSGLData {
    address user;
    uint256 lendAmount;
    IMintData mintData;
    IDepositData depositData;
    ITapiocaOptionLiquidityProvision.IOptionsLockData lockData;
    ITapiocaOptionBroker.IOptionsParticipateData participateData;
    ICommonExternalContracts externalContracts;
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
    Wrap, //1 Wrap/unwrap singular operations.
    Market, //2 Market singular operations.
    TapToken, //3 TapToken singular operations.
    OFT, //4 LZ OFT singular operations.
    AssetModule, //5  Usdo Singular operations.
    CollateralModule, //6 Collateral Singular related operations.
    MintModule, //7 BigBang Singular related operations.
    OptionModule, //8 Market Module related operations.
    YieldBoxModule //9 YieldBox module related operations.
}

enum MagnetarModule {
    AssetModule,
    CollateralModule,
    MintModule,
    OptionModule,
    YieldBoxModule
}

// TODO: fill
interface IMagnetar {
    function burst(MagnetarCall[] calldata calls) external payable;

    function MAGNETAR_ACTION_PERMIT() external view returns (uint8);

    function MAGNETAR_ACTION_WRAP() external view returns (uint8);

    function MAGNETAR_ACTION_MARKET() external view returns (uint8);

    function MAGNETAR_ACTION_TAP_TOKEN() external view returns (uint8);

    function MAGNETAR_ACTION_OFT() external view returns (uint8);

    function MAGNETAR_ACTION_ASSET_MODULE() external view returns (uint8);

    function MAGNETAR_ACTION_COLLATERAL_MODULE() external view returns (uint8);

    function MAGNETAR_ACTION_MINT_MODULE() external view returns (uint8);

    function MAGNETAR_ACTION_OPTION_MODULE() external view returns (uint8);

    function MAGNETAR_ACTION_YIELDBOX_MODULE() external view returns (uint8);

    function cluster() external view returns (address);

    function helper() external view returns (address);
}
