// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

// Tapioca
import {ITapiocaOmnichainEngine, LZSendParam, ERC20PermitStruct} from "../periph/ITapiocaOmnichainEngine.sol";
import {ICommonData, ICommonExternalContracts} from "../common/ICommonData.sol";
import {
    ITapiocaOptionBroker,
    IExerciseOptionsData,
    IOptionsParticipateData,
    IOptionsExitData
} from "../tap-token/ITapiocaOptionBroker.sol";
import {IOptionsUnlockData, IOptionsLockData} from "../tap-token/ITapiocaOptionLiquidityProvision.sol";
import {MagnetarWithdrawData} from "../periph/IMagnetar.sol";
import {IDepositData} from "../common/ICommonData.sol";

/*
__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

interface IUsdo is ITapiocaOmnichainEngine {
    enum Module {
        NonModule,
        UsdoSender,
        UsdoReceiver,
        UsdoMarketReceiver,
        UsdoOptionReceiver,
        UsdoGenericReceiver,
        UsdoLeverageReceiver
    }

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function setFlashloanHelper(address _helper) external;

    function addFlashloanFee(uint256 _fee) external; //onlyOwner

    function paused() external view returns (bool);
}

/// ============================
/// ========= GENERIC ==========
/// ============================
struct UsdoInitStruct {
    address endpoint;
    address delegate;
    address yieldBox;
    address cluster;
    address extExec;
}

struct UsdoModulesInitStruct {
    //modules
    address usdoSenderModule;
    address usdoReceiverModule;
    address marketReceiverModule;
    address optionReceiverModule;
    address leverageReceiverModule;
}

/// ============================
/// ========= COMPOSE ==========
/// ============================
/**
 * @notice Encodes the message for the PT_YB_SEND_SGL_LEND_OR_REPAY operation.
 */
struct MarketLendOrRepayMsg {
    address user;
    ILendOrRepayParams lendParams;
    MagnetarWithdrawData withdrawParams;
}

/**
 * @notice Encodes the message for the PT_MARKET_REMOVE_ASSET operation.
 */
struct MarketRemoveAssetMsg {
    address user;
    ICommonExternalContracts externalData;
    IRemoveAndRepay removeAndRepayData;
}

/**
 * @notice Encodes the message for the PT_LEVERAGE_MARKET_UP operation.
 */
struct MarketLeverageUpMsg {
    address user;
    uint256 amount;
    ILeverageSwapData swapData;
    ILeverageExternalContractsData externalData;
    //@dev send back to source message params
    LZSendParam lzSendParams;
    bytes composeMsg;
    uint128 composeGas;
}

/**
 * @notice Encodes the message for the PT_TAP_EXERCISE operation.
 */
struct ExerciseOptionsMsg {
    IExerciseOptionsData optionsData;
    bool withdrawOnOtherChain;
    //@dev send back to source message params
    LZSendParam lzSendParams;
    bytes composeMsg;
}

/**
 * @notice Encodes the message for the ybPermitAll() operation.
 */
struct YieldBoxApproveAllMsg {
    address target;
    address owner;
    address spender;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permit;
}

/**
 * @notice Encodes the message for the ybPermitAll() operation.
 */
struct YieldBoxApproveAssetMsg {
    address target;
    address owner;
    address spender;
    uint256 assetId;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permit;
}

/**
 * @notice Encodes the message for the market.permitAction() or market.permitBorrow() operations.
 */
struct MarketPermitActionMsg {
    address target;
    uint16 actionType;
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permitAsset;
}

// remove and repay
struct ILeverageExternalContractsData {
    address swapper;
    address magnetar;
    address tOft;
    address srcMarket;
}

struct IRemoveAndRepay {
    bool removeAssetFromSGL;
    uint256 removeAmount; //slightly greater than repayAmount to cover the interest
    bool repayAssetOnBB;
    uint256 repayAmount; // on BB
    bool removeCollateralFromBB;
    uint256 collateralAmount; // from BB
    IOptionsExitData exitData;
    IOptionsUnlockData unlockData;
    MagnetarWithdrawData assetWithdrawData;
    MagnetarWithdrawData collateralWithdrawData;
}

// lend or repay
struct ILendOrRepayParams {
    bool repay;
    uint256 depositAmount;
    uint256 repayAmount;
    address marketHelper;
    address market;
    bool removeCollateral;
    uint256 removeCollateralAmount;
    IOptionsLockData lockData;
    IOptionsParticipateData participateData;
}

//leverage data
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

struct IMintData {
    bool mint;
    uint256 mintAmount;
    IDepositData collateralDepositData;
}
