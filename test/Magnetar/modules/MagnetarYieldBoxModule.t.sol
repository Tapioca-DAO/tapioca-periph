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
            unwrap: false,
            extractFromSender: false
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

    function test_withdrawHere_with_sender_extraction() public {
        uint256 tokenAmount_ = 1 ether;

        {
            deal(address(assetA), address(this), tokenAmount_);
            assetA.approve(address(yieldBox), type(uint256).max);
            _setYieldBoxApproval(yieldBox, address(magnetarA));
        }

        // test market
        YieldBoxDepositData memory _params = _createYieldBoxDepositData(address(yieldBox), assetAId, tokenAmount_, 0);
        bytes memory callParams = abi.encodeWithSelector(MagnetarYieldBoxModule.depositAsset.selector, _params);

        MagnetarWithdrawData memory _withdrawParams = _createWithdrawData(address(yieldBox), assetAId, tokenAmount_);
        _withdrawParams.extractFromSender = true;
        bytes memory withdrawCallParams = abi.encodeWithSelector(MagnetarYieldBoxModule.withdrawHere.selector, _withdrawParams);

        pearlmit.approve(1155, address(yieldBox), assetAId, address(magnetarA), type(uint200).max, uint48(block.timestamp));
        yieldBox.setApprovalForAll(address(pearlmit), true);
        // assetA.approve(address(pearlmit), type(uint256).max);

        MagnetarCall[] memory calls = new MagnetarCall[](2);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.YieldBoxModule),
            target: address(magnetarA),
            value: 0,
            call: callParams
        });
        calls[1] = MagnetarCall({
            id: uint8(MagnetarAction.YieldBoxModule),
            target: address(magnetarA),
            value: 0,
            call: withdrawCallParams
        });
        magnetarA.burst{value: 0}(calls);

        _setYieldBoxRevoke(yieldBox, address(magnetarA));
    }

    function test_should_fail_withdrawHere_with_sender_extraction_when_sender_is_whitelisted() public {
        uint256 tokenAmount_ = 1 ether;

        {
            deal(address(assetA), address(this), tokenAmount_);
            assetA.approve(address(yieldBox), type(uint256).max);
            _setYieldBoxApproval(yieldBox, address(magnetarA));
        }

        // test market
        YieldBoxDepositData memory _params = _createYieldBoxDepositData(address(yieldBox), assetAId, tokenAmount_, 0);
        bytes memory callParams = abi.encodeWithSelector(MagnetarYieldBoxModule.depositAsset.selector, _params);

        MagnetarWithdrawData memory _withdrawParams = _createWithdrawData(address(yieldBox), assetAId, tokenAmount_);
        _withdrawParams.extractFromSender = true;
        bytes memory withdrawCallParams = abi.encodeWithSelector(MagnetarYieldBoxModule.withdrawHere.selector, _withdrawParams);

        MagnetarCall[] memory calls = new MagnetarCall[](2);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.YieldBoxModule),
            target: address(magnetarA),
            value: 0,
            call: callParams
        });
        calls[1] = MagnetarCall({
            id: uint8(MagnetarAction.YieldBoxModule),
            target: address(magnetarA),
            value: 0,
            call: withdrawCallParams
        });

        clusterA.updateContract(0, address(this), true);
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _setYieldBoxRevoke(yieldBox, address(magnetarA));
    }

}
