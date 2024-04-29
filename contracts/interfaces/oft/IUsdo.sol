// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {
    ITapiocaOmnichainEngine,
    YieldBoxApproveAssetMsg,
    YieldBoxApproveAllMsg,
    MarketPermitActionMsg,
    ERC20PermitStruct,
    LZSendParam
} from "../periph/ITapiocaOmnichainEngine.sol";
import {
    IOptionsParticipateData,
    ITapiocaOptionBroker,
    IExerciseOptionsData,
    IOptionsExitData
} from "../tap-token/ITapiocaOptionBroker.sol";
import {IOptionsUnlockData, IOptionsLockData} from "../tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ICommonData, ICommonExternalContracts} from "../common/ICommonData.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {MagnetarWithdrawData} from "../periph/IMagnetar.sol";
import {IDepositData} from "../common/ICommonData.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IUsdo is ITapiocaOmnichainEngine {
    enum Module {
        NonModule,
        UsdoSender,
        UsdoReceiver,
        UsdoMarketReceiver,
        UsdoOptionReceiver,
        UsdoGenericReceiver
    }

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function setFlashloanHelper(address _helper) external;

    function addFlashloanFee(uint256 _fee) external; //onlyOwner

    function paused() external view returns (bool);

    // available in BaseTapiocaOmnichainEngine
    function removeDust(uint256 _amountLD) external view returns (uint256 amountLD);
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
    IPearlmit pearlmit;
}

struct UsdoModulesInitStruct {
    //modules
    address usdoSenderModule;
    address usdoReceiverModule;
    address marketReceiverModule;
    address optionReceiverModule;
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
 * @notice Encodes the message for the PT_TAP_EXERCISE operation.
 */
struct ExerciseOptionsMsg {
    IExerciseOptionsData optionsData;
    bool withdrawOnOtherChain;
    //@dev send back to source message params
    LZSendParam lzSendParams;
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
    address magnetar;
    address market;
    bool removeCollateral;
    uint256 removeCollateralAmount;
    IOptionsLockData lockData;
    IOptionsParticipateData participateData;
}

struct IMintData {
    bool mint;
    uint256 mintAmount;
    IDepositData collateralDepositData;
}
