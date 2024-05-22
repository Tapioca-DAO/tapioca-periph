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

    function _createWithdrawData(address yieldBox, uint256 assetId, uint256 amount)
        public
        returns (MagnetarWithdrawData memory)
    {
        return MagnetarWithdrawData({
            yieldBox: yieldBox,
            assetId: assetId,
            receiver: address(this),
            amount: amount,
            withdraw: true,
            unwrap: false
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

    function test_depositAsset() public {
        // test market
        YieldBoxDepositData memory _params = _createYieldBoxDepositData(address(yieldBox), assetAId, 1 ether, 0);
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

    function test_withdrawHere_validation() public {
        MagnetarCall[] memory calls = new MagnetarCall[](1);
        address randomAddr = makeAddr("not_whitelisted");

        // test market
        MagnetarWithdrawData memory _params = _createWithdrawData(randomAddr, assetAId, 1 ether);
        bytes memory callParams = abi.encodeWithSelector(MagnetarYieldBoxModule.withdrawHere.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.YieldBoxModule),
            target: address(magnetarA),
            value: 0,
            call: callParams
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.yieldBox = address(yieldBox);
        _params.amount = 0;
        callParams = abi.encodeWithSelector(MagnetarYieldBoxModule.withdrawHere.selector, _params);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.YieldBoxModule),
            target: address(magnetarA),
            value: 0,
            call: callParams
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.amount = 1 ether;
        _params.withdraw = false;
        callParams = abi.encodeWithSelector(MagnetarYieldBoxModule.withdrawHere.selector, _params);
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
