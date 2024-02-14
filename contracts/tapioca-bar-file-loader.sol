// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// THIS FILE IS USED TO LOAD THE TAPIOCA BAR CONTRACTS
/// Comment the imports for faster compilation

import {
    Singularity,
    SGLLiquidation,
    SGLCollateral,
    SGLLeverage,
    SGLCommon,
    SGLBorrow
} from "tapioca-bar/markets/singularity/Singularity.sol";
import {
    BigBang,
    BBLiquidation,
    BBCollateral,
    BBLeverage,
    BBCommon,
    BBBorrow
} from "tapioca-bar/markets/bigBang/BigBang.sol";
import {Penrose} from "tapioca-bar/Penrose.sol";
import {SimpleLeverageExecutor} from "tapioca-bar/markets/leverage/SimpleLeverageExecutor.sol";

// import {UsdoSender} from "tapioca-bar/usdo/modules/UsdoSender.sol";
// import {UsdoReceiver} from "tapioca-bar/usdo/modules/UsdoReceiver.sol";
// import {UsdoMarketReceiverModule} from "tapioca-bar/usdo/modules/UsdoMarketReceiverModule.sol";
// import {UsdoOptionReceiverModule} from "tapioca-bar/usdo/modules/UsdoOptionReceiverModule.sol";
// import {ModuleManager} from "tapioca-bar/usdo/modules/ModuleManager.sol";
// import {Usdo, BaseUsdo} from "tapioca-bar/usdo/Usdo.sol";
