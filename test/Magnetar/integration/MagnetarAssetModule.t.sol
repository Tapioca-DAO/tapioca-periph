// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {MagnetarTestHelper, MagnetarSetupData, TestBigBangData, TestSingularityData} from "./MagnetarTestHelper.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MagnetarTest is MagnetarTestHelper {
    function setUp() public override {
        createCommonSetup();
    }
}
