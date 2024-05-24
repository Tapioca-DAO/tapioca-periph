// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {IExerciseOptionsData} from "../tap-token/ITapiocaOptionBroker.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {MagnetarWithdrawData} from "../periph/IMagnetar.sol";

import "../periph/ITapiocaOmnichainEngine.sol";
/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ITOFT is ITapiocaOmnichainEngine {
    enum Module {
        NonModule, //0
        TOFTSender,
        TOFTReceiver,
        TOFTMarketReceiver,
        TOFTOptionsReceiver,
        TOFTGenericReceiver
    }

    function decimalConversionRate() external view returns (uint256);
    function hostEid() external view returns (uint256);
    function wrap(address fromAddress, address toAddress, uint256 amount) external payable returns (uint256 minted);
    function unwrap(address _toAddress, uint256 _amount) external returns (uint256 unwrapped);
    function erc20() external view returns (address);
    function vault() external view returns (address);
    function balanceOf(address _holder) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function extractUnderlying(uint256 _amount) external; //mTOFT
    // available in BaseTapiocaOmnichainEngine
    function removeDust(uint256 _amountLD) external view returns (uint256 amountLD);
}

interface IToftVault {
    error AmountNotRight();
    error Failed();
    error FeesAmountNotRight();
    error NotValid();
    error OwnerSet();
    error ZeroAmount();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _token() external view returns (address);
    function claimOwnership() external;
    function depositNative() external payable;
    function owner() external view returns (address);
    function registerFees(uint256 amount) external payable;
    function renounceOwnership() external;
    function transferFees(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
    function viewFees() external view returns (uint256);
    function viewSupply() external view returns (uint256);
    function viewTotalSupply() external view returns (uint256);
    function withdraw(address to, uint256 amount) external;
}

/// ============================
/// ========= GENERIC ==========
/// ============================

struct TOFTInitStruct {
    string name;
    string symbol;
    address endpoint;
    address delegate;
    address yieldBox;
    address cluster;
    address erc20;
    address vault;
    uint256 hostEid;
    address extExec;
    IPearlmit pearlmit;
}

struct TOFTModulesInitStruct {
    //modules
    address tOFTSenderModule;
    address tOFTReceiverModule;
    address marketReceiverModule;
    address optionsReceiverModule;
    address genericReceiverModule;
}

/// ============================
/// ========= COMPOSE ==========
/// ============================

/**
 * @notice Encodes the message for the PT_SEND_PARAMS operation.
 */
struct SendParamsMsg {
    address receiver;
    bool unwrap;
    uint256 amount;
}

/**
 * @notice Encodes the message for the PT_TAP_EXERCISE operation.
 */
struct ExerciseOptionsMsg {
    IExerciseOptionsData optionsData;
    bool withdrawOnOtherChain;
    //@dev send back to source message params
    LZSendParam lzSendParams;
}

/**
 * @notice Encodes the message for the PT_MARKET_REMOVE_COLLATERAL operation.
 */
struct MarketRemoveCollateralMsg {
    address user;
    IRemoveParams removeParams;
    MagnetarWithdrawData withdrawParams;
    uint256 value;
}

/**
 * @notice Encodes the message for the PT_YB_SEND_SGL_BORROW operation.
 */
struct MarketBorrowMsg {
    address user;
    IBorrowParams borrowParams;
    MagnetarWithdrawData withdrawParams;
    uint256 value;
}

struct IRemoveParams {
    uint256 amount;
    address magnetar;
    address marketHelper;
    address market;
}

struct IBorrowParams {
    uint256 amount;
    uint256 borrowAmount;
    address magnetar;
    address marketHelper;
    address market;
    bool deposit;
}

struct LeverageUpActionMsg {
    address user;
    address market;
    address marketHelper;
    uint256 borrowAmount;
    uint256 supplyAmount;
    bytes executorData;
}
