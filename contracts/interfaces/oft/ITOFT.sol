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
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";

import {IUSDOBase, ILeverageSwapData, ILeverageExternalContractsData} from "tapioca-periph/interfaces/bar/IUSDO.sol";
import {ITapiocaOFT, IRemoveParams, IBorrowParams} from "tapioca-periph/interfaces/tap-token/ITapiocaOFT.sol";
import {ITapiocaOptionBrokerCrossChain} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ICommonData, IWithdrawParams} from "tapioca-periph/interfaces/common/ICommonData.sol";

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

interface ITOFT is ITapiocaOmnichainEngine {
    enum Module {
        NonModule, //0
        TOFTSender,
        TOFTReceiver,
        TOFTMarketReceiver,
        TOFTOptionsReceiver,
        TOFTGenericReceiver
    }
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
    address toftVault;
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
    ITapiocaOptionBrokerCrossChain.IExerciseOptionsData optionsData;
    bool withdrawOnOtherChain;
    //@dev send back to source message params
    LZSendParam lzSendParams;
    bytes composeMsg;
}

/**
 * @notice Encodes the message for the PT_LEVERAGE_MARKET_DOWN operation.
 */
struct MarketLeverageDownMsg {
    address user;
    uint256 amount;
    ILeverageSwapData swapData;
    ILeverageExternalContractsData externalData;
    //@dev send back to source message params
    LZSendParam lzSendParams;
    bytes composeMsg;
}

/**
 * @notice Encodes the message for the PT_MARKET_REMOVE_COLLATERAL operation.
 */
struct MarketRemoveCollateralMsg {
    address user;
    IRemoveParams removeParams;
    IWithdrawParams withdrawParams;
}

/**
 * @notice Encodes the message for the PT_YB_SEND_SGL_BORROW operation.
 */
struct MarketBorrowMsg {
    address user;
    IBorrowParams borrowParams;
    IWithdrawParams withdrawParams;
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
