// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {MarketLendOrRepayMsg, MarketRemoveAssetMsg, ExerciseOptionsMsg} from "tapioca-periph/interfaces/oft/IUsdo.sol";
import {
    MarketBorrowMsg, MarketRemoveCollateralMsg, LeverageUpActionMsg
} from "tapioca-periph/interfaces/oft/ITOFT.sol";

// @dev Used only to include structs into the ABI
interface IABIGeneration {
    //does nothing
    //for ABI generation only

    function MarketLendOrRepayMsg(MarketLendOrRepayMsg calldata) external pure returns (uint256);
    function MarketRemoveAssetMsg(MarketRemoveAssetMsg calldata) external pure returns (uint256);
    function ExerciseOptionsMsg(ExerciseOptionsMsg calldata) external pure returns (uint256);
    function MarketRemoveCollateralMsg(MarketRemoveCollateralMsg calldata) external pure returns (uint256);
    function MarketBorrowMsg(MarketBorrowMsg calldata) external pure returns (uint256);
    function LeverageUpActionMsg(LeverageUpActionMsg calldata) external pure returns (uint256);
}
