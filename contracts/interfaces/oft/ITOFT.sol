// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

// Tapioca
import {
    ITapiocaOmnichainEngine,
    LZSendParam,
    ERC20PermitStruct,
    ERC20PermitApprovalMsg,
    RemoteTransferMsg
} from "../periph/ITapiocaOmnichainEngine.sol";
import {ITapiocaOptionBroker, IExerciseOptionsData} from "../tap-token/ITapiocaOptionBroker.sol";
import {MagnetarWithdrawData} from "../periph/IMagnetar.sol";
import {ICommonData} from "../common/ICommonData.sol";

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

    function hostEid() external view returns (uint256);

    function wrap(address fromAddress, address toAddress, uint256 amount) external payable returns (uint256 minted);

    function unwrap(address _toAddress, uint256 _amount) external;

    function erc20() external view returns (address);

    function vault() external view returns (address);

    function balanceOf(address _holder) external view returns (uint256);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function extractUnderlying(uint256 _amount) external; //mTOFT
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
    uint256 hostEid;
    address extExec;
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
    address receiver; //TODO: decide if we should use `srcChainSender_`
    bool unwrap;
    uint256 amount; //TODO: use the amount credited by lzReceive directly
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
 * @notice Encodes the message for the PT_LOCK_AND_PARTICIPATE operation.
 */
struct LockAndParticipateMsg {
    
}

/**
 * @notice Encodes the message for the PT_MARKET_REMOVE_COLLATERAL operation.
 */
struct MarketRemoveCollateralMsg {
    address user;
    IRemoveParams removeParams;
    MagnetarWithdrawData withdrawParams;
}

/**
 * @notice Encodes the message for the PT_YB_SEND_SGL_BORROW operation.
 */
struct MarketBorrowMsg {
    address user;
    IBorrowParams borrowParams;
    MagnetarWithdrawData withdrawParams;
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
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permitAsset;
}

struct IRemoveParams {
    uint256 amount;
    address marketHelper;
    address market;
}

struct IBorrowParams {
    uint256 amount;
    uint256 borrowAmount;
    address marketHelper;
    address market;
    bool deposit;
}
