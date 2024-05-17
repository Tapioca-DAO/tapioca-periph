// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {MagnetarTestHelper, MagnetarSetupData, TestBigBangData, TestSingularityData} from "./MagnetarTestHelper.sol";
import {
    MagnetarAction,
    MagnetarModule,
    MagnetarCall,
    MagnetarWithdrawData,
    YieldBoxDepositData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {MagnetarYieldBoxModule} from "tapioca-periph/Magnetar/modules/MagnetarYieldBoxModule.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MagnetarYieldBoxModuleTest is MagnetarTestHelper {
    // -----------------------
    //
    // Setup
    //
    // -----------------------
    function setUp() public override {
        createCommonSetup();
    }

    function _createYieldBoxDepositData(address yieldBox, uint256 assetId, uint256 amount, uint256 share)
        private
        returns (YieldBoxDepositData memory _params)
    {
        _params = YieldBoxDepositData({
            yieldBox: yieldBox,
            assetId: assetId,
            from: address(this),
            to: address(this),
            amount: amount,
            share: share
        });
    }
    // -----------------------
    //
    // Tests
    //
    // -----------------------

    function test_depositAsset_validation() public {
        address randomAddr = makeAddr("not_whitelisted");

        // test market
        YieldBoxDepositData memory _params = _createYieldBoxDepositData(randomAddr, assetAId, 1 ether, 0);
        bytes memory callParams = abi.encodeWithSelector(MagnetarYieldBoxModule.depositAsset.selector, _params);

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.YieldBoxModule),
            target: address(magnetarA),
            value: 0,
            call: callParams
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);
    }
}
