// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {MagnetarTestHelper, MagnetarSetupData, TestBigBangData, TestSingularityData} from "./MagnetarTestHelper.sol";
import {
    MagnetarAction,
    MagnetarModule,
    MagnetarCall,
    MagnetarWithdrawData,
    DepositRepayAndRemoveCollateralFromMarketData,
    DepositAddCollateralAndBorrowFromMarketData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";

import {ERC20PermitStruct} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarCollateralModule} from "tapioca-periph/Magnetar/modules/MagnetarCollateralModule.sol";

import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {IPermit} from "tapioca-periph/interfaces/common/IPermit.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MagnetarCollateralModuleTest is MagnetarTestHelper {
    // -----------------------
    //
    // Setup
    //
    // -----------------------
    function setUp() public override {
        createCommonSetup();
    }

    function _createDepositRepayAndRemoveCollateralFromMarketData(
        address market,
        address marketHelper,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount
    ) private returns (DepositRepayAndRemoveCollateralFromMarketData memory _params) {
        MagnetarWithdrawData memory _withdrawData = createEmptyWithdrawData();
        _params = DepositRepayAndRemoveCollateralFromMarketData({
            market: market,
            marketHelper: marketHelper,
            user: user,
            depositAmount: depositAmount,
            repayAmount: repayAmount,
            collateralAmount: collateralAmount,
            withdrawCollateralParams: _withdrawData
        });
    }

    function _createDepositAddCollateralAndBorrowFromMarketData(
        address market,
        address marketHelper,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool deposit
    ) private returns (DepositAddCollateralAndBorrowFromMarketData memory _params) {
        MagnetarWithdrawData memory _withdrawData = createEmptyWithdrawData();
        _params = DepositAddCollateralAndBorrowFromMarketData({
            market: market,
            marketHelper: marketHelper,
            user: user,
            collateralAmount: collateralAmount,
            borrowAmount: borrowAmount,
            deposit: deposit,
            withdrawParams: _withdrawData
        });
    }

    // -----------------------0
    //
    // Tests
    //
    // -----------------------
    function test_depositRepayAndRemoveCollateralFromMarket_validation() public {
        address randomAddr = makeAddr("not_whitelisted");
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        DepositRepayAndRemoveCollateralFromMarketData memory _params =
        _createDepositRepayAndRemoveCollateralFromMarketData(
            randomAddr, address(marketHelper), address(this), 1 ether, 1 ether, 1 ether
        );
        bytes memory depositRepayAndRemoveCollateralFromMarketData =
            abi.encodeWithSelector(MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        // test marketHelper
        _params.market = address(magnetarA);
        _params.marketHelper = randomAddr;
        depositRepayAndRemoveCollateralFromMarketData =
            abi.encodeWithSelector(MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector, _params);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);
    }

    function test_depositRepayAndRemoveCollateralFromMarket_deposit_external_approvals() public {
        uint256 tokenAmount_ = 1 ether;
        {
            deal(address(assetA), address(this), tokenAmount_);
        }

        DepositRepayAndRemoveCollateralFromMarketData memory _params = _createDepositRepayAndRemoveCollateralFromMarketData(address(sgl), address(marketHelper), address(this), tokenAmount_, 0, 0);
        bytes memory depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });

        uint256 ybBalanceBefore = yieldBox.balanceOf(address(this), assetAId);

        //aprovals 
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        assetA.approve(address(pearlmit), type(uint256).max);

        magnetarA.burst{value: 0}(calls);
        assetA.approve(address(pearlmit), 0);

        uint256 ybBalanceAfter = yieldBox.balanceOf(address(this), assetAId);
        assertGt(ybBalanceAfter, ybBalanceBefore);
    }

    function test_depositRepayAndRemoveCollateralFromMarket_deposit_burst_approvals() public {
        //TODO: check pearlmit batch
        uint256 tokenAmount_ = 1 ether;
        {
            deal(address(assetA), userA, tokenAmount_);
        }

        DepositRepayAndRemoveCollateralFromMarketData memory _params = _createDepositRepayAndRemoveCollateralFromMarketData(address(sgl), address(marketHelper), userA, tokenAmount_, 0, 0);
        bytes memory depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );

        MagnetarCall[] memory calls = new MagnetarCall[](2);
        (IPearlmit.PermitBatchTransferFrom memory pearlmitBatch, bytes32 hashedData) = _createErc20PearlmitBatchPermit(Erc20PearlmitBatchPermitInternal(address(assetA), 0, userA, userAPKey, address(magnetarA), type(uint200).max, uint48(block.timestamp + 10000000)));
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.Permit),
            target: address(pearlmit),
            value: 0,
            call: abi.encodeWithSelector(
                IPearlmit.permitBatchApprove.selector,
                pearlmitBatch,
                hashedData
            )
        });

        (ERC20PermitStruct memory permit, uint8 v_, bytes32 r_, bytes32 s_) = _createErc20Permit(userA, userAPKey, address(pearlmit), type(uint256).max, address(assetA));
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.Permit),
            target: address(assetA),
            value: 0,
            call: abi.encodeWithSelector(
                IPermit.permit.selector,
                permit.owner,
                permit.spender,
                permit.value,
                permit.deadline,
                v_,
                r_,
                s_
            )
        });
        
        calls[1] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });

        uint256 ybBalanceBefore = yieldBox.balanceOf(userA, assetAId);
        //aprovals 
        vm.startPrank(userA);
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        magnetarA.burst{value: 0}(calls);
        vm.stopPrank();

        uint256 ybBalanceAfter = yieldBox.balanceOf(userA, assetAId);
        assertGt(ybBalanceAfter, ybBalanceBefore);
    }

    function test_depositRepayAndRemoveCollateralFromMarket_deposit_and_repay() public {
        uint256 tokenAmount_ = 1 ether;
        
        // setup SGL funds
        // ---- add asset
        // ---- add collateral
        // ---- borrow
        deal(address(assetA), address(this), tokenAmount_ * 2);
        depositAsset(assetA, assetAId, sgl, tokenAmount_ * 2);
        deal(address(collateralA), address(this), tokenAmount_ * 10);
        depositCollateral(collateralA, collateralAId, sgl, tokenAmount_ * 10);
        borrow(sgl, tokenAmount_, false);

        // use magnetar to `depositRepayAndRemoveCollateralFromMarket`
        deal(address(assetA), address(this), tokenAmount_);

        DepositRepayAndRemoveCollateralFromMarketData memory _params = _createDepositRepayAndRemoveCollateralFromMarketData(address(sgl), address(marketHelper), address(this), tokenAmount_, tokenAmount_, 0);
        bytes memory depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });
        uint256 borrowPartBefore = sgl._userBorrowPart(address(this));

        //aprovals for deposit 
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); 
        assetA.approve(address(pearlmit), type(uint256).max);

        //approvals for repay
        pearlmit.approve(1155, address(yieldBox), assetAId, address(sgl), type(uint200).max, uint48(block.timestamp));
        sgl.approve(address(magnetarA),  type(uint256).max);
        _setYieldBoxApproval(yieldBox, address(pearlmit));

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        assetA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 borrowPartAfter = sgl._userBorrowPart(address(this));
        assertGt(borrowPartBefore, borrowPartAfter);
    }

    function test_depositRepayAndRemoveCollateralFromMarket_deposit_repay_and_remove_collateral() public {
        uint256 tokenAmount_ = 1 ether;
        
        // setup SGL funds
        // ---- add asset
        // ---- add collateral
        // ---- borrow
        deal(address(assetA), address(this), tokenAmount_ * 2);
        depositAsset(assetA, assetAId, sgl, tokenAmount_ * 2);
        deal(address(collateralA), address(this), tokenAmount_ * 10);
        depositCollateral(collateralA, collateralAId, sgl, tokenAmount_ * 10);
        borrow(sgl, tokenAmount_, false);


        // use magnetar to `depositRepayAndRemoveCollateralFromMarket`
        deal(address(assetA), address(this), tokenAmount_);

        DepositRepayAndRemoveCollateralFromMarketData memory _params = _createDepositRepayAndRemoveCollateralFromMarketData(address(sgl), address(marketHelper), address(this), tokenAmount_, tokenAmount_, tokenAmount_);
        bytes memory depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });

        uint256 collateralShareBefore = sgl._userCollateralShare(address(this));

        //aprovals for deposit 
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); 
        assetA.approve(address(pearlmit), type(uint256).max);

        //approvals for repay
        pearlmit.approve(1155, address(yieldBox), assetAId, address(sgl), type(uint200).max, uint48(block.timestamp));
        sgl.approve(address(magnetarA),  type(uint256).max);
        _setYieldBoxApproval(yieldBox, address(pearlmit));

        //approvals for collateral
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)); 


        magnetarA.burst{value: 0}(calls);

        assetA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 collateralShareAfter = sgl._userCollateralShare(address(this));
        assertGt(collateralShareBefore, collateralShareAfter);
    }

    function test_depositRepayAndRemoveCollateralFromMarket_deposit_and_remove_collateral() public {
        uint256 tokenAmount_ = 1 ether;
        
        // setup SGL funds
        // ---- add asset
        // ---- add collateral
        // ---- borrow
        deal(address(assetA), address(this), tokenAmount_ * 2);
        depositAsset(assetA, assetAId, sgl, tokenAmount_ * 2);
        deal(address(collateralA), address(this), tokenAmount_ * 10);
        depositCollateral(collateralA, collateralAId, sgl, tokenAmount_ * 10);
        borrow(sgl, tokenAmount_, false);


        // use magnetar to `depositRepayAndRemoveCollateralFromMarket`
        deal(address(assetA), address(this), tokenAmount_);

        DepositRepayAndRemoveCollateralFromMarketData memory _params = _createDepositRepayAndRemoveCollateralFromMarketData(address(sgl), address(marketHelper), address(this), tokenAmount_, 0, tokenAmount_);
        bytes memory depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });

        uint256 collateralShareBefore = sgl._userCollateralShare(address(this));

        //aprovals for deposit 
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); 
        assetA.approve(address(pearlmit), type(uint256).max);

        //approvals for collateral
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)); 
        _setYieldBoxApproval(yieldBox, address(pearlmit));


        magnetarA.burst{value: 0}(calls);

        assetA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 collateralShareAfter = sgl._userCollateralShare(address(this));
        assertGt(collateralShareBefore, collateralShareAfter);
    }

    function test_depositRepayAndRemoveCollateralFromMarket_deposit_remove_collateral_and_withdraw() public {
        uint256 tokenAmount_ = 1 ether;
        
        // setup SGL funds
        // ---- add asset
        // ---- add collateral
        // ---- borrow
        deal(address(assetA), address(this), tokenAmount_ * 2);
        depositAsset(assetA, assetAId, sgl, tokenAmount_ * 2);
        deal(address(collateralA), address(this), tokenAmount_ * 10);
        depositCollateral(collateralA, collateralAId, sgl, tokenAmount_ * 10);
        borrow(sgl, tokenAmount_, false);


        // use magnetar to `depositRepayAndRemoveCollateralFromMarket`
        deal(address(assetA), address(this), tokenAmount_);

        DepositRepayAndRemoveCollateralFromMarketData memory _params = _createDepositRepayAndRemoveCollateralFromMarketData(address(sgl), address(marketHelper), address(this), tokenAmount_, 0, tokenAmount_);
        _params.withdrawCollateralParams = MagnetarWithdrawData({
            yieldBox: address(yieldBox),
            assetId: collateralAId,
            receiver: userA,
            amount: tokenAmount_,
            withdraw: true,
            unwrap: false,
            extractFromSender: false
        });
        bytes memory depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });

        uint256 collateralShareBefore = sgl._userCollateralShare(address(this));
        uint256 userABalanceBefore = collateralA.balanceOf(userA);

        //aprovals for deposit 
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); 
        assetA.approve(address(pearlmit), type(uint256).max);

        //approvals for collateral
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)); 
        _setYieldBoxApproval(yieldBox, address(pearlmit));


        magnetarA.burst{value: 0}(calls);

        assetA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 collateralShareAfter = sgl._userCollateralShare(address(this));
        assertGt(collateralShareBefore, collateralShareAfter);

        uint256 userABalanceAfter = collateralA.balanceOf(userA);
        assertGt(userABalanceAfter, userABalanceBefore);
        assertEq(userABalanceAfter, tokenAmount_);
    }

    function test_depositRepayAndRemoveCollateralFromMarket_deposit_remove_collateral_and_unwrap_withdraw() public {
        uint256 tokenAmount_ = 1 ether;
        
        // setup SGL funds
        // ---- add asset
        // ---- add collateral
        // ---- borrow
        deal(address(assetA), address(this), tokenAmount_ * 2);
        depositAsset(assetA, assetAId, sgl, tokenAmount_ * 2);
        deal(address(collateralA), address(this), tokenAmount_ * 10);
        depositCollateral(collateralA, collateralAId, sgl, tokenAmount_ * 10);
        borrow(sgl, tokenAmount_, false);


        // use magnetar to `depositRepayAndRemoveCollateralFromMarket`
        deal(address(assetA), address(this), tokenAmount_);

        // deal collateralErc20 for unwrap operation
        deal(address(collateralErc20), address(collateralA.vault()), tokenAmount_);

        DepositRepayAndRemoveCollateralFromMarketData memory _params = _createDepositRepayAndRemoveCollateralFromMarketData(address(sgl), address(marketHelper), address(this), tokenAmount_, 0, tokenAmount_);
        _params.withdrawCollateralParams = MagnetarWithdrawData({
            yieldBox: address(yieldBox),
            assetId: collateralAId,
            receiver: userA,
            amount: tokenAmount_,
            withdraw: true,
            unwrap: true,
            extractFromSender: false
        });
        bytes memory depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });

        uint256 collateralShareBefore = sgl._userCollateralShare(address(this));
        uint256 userABalanceBefore = collateralErc20.balanceOf(userA);

        //aprovals for deposit 
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); 
        assetA.approve(address(pearlmit), type(uint256).max);

        //approvals for collateral
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)); 
        _setYieldBoxApproval(yieldBox, address(pearlmit));


        magnetarA.burst{value: 0}(calls);

        assetA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 collateralShareAfter = sgl._userCollateralShare(address(this));
        assertGt(collateralShareBefore, collateralShareAfter);

        uint256 userABalanceAfter = collateralErc20.balanceOf(userA);
        assertGt(userABalanceAfter, userABalanceBefore);
        assertEq(userABalanceAfter, tokenAmount_);
    }

    function test_depositRepayAndRemoveCollateralFromMarket_deposit_different_user() public {
        uint256 tokenAmount_ = 1 ether;
        {
            deal(address(assetA), userA, tokenAmount_);
        }

        DepositRepayAndRemoveCollateralFromMarketData memory _params = _createDepositRepayAndRemoveCollateralFromMarketData(address(sgl), address(marketHelper), address(this), tokenAmount_, 0, 0);
        _params.user = userA;
        bytes memory depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });

        uint256 ybBalanceBefore = yieldBox.balanceOf(userA, assetAId);

        //aprovals 
        vm.startPrank(userA);
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        assetA.approve(address(pearlmit), type(uint256).max);
        vm.stopPrank();

        //authorize user
        clusterA.updateContract(0, address(this), true);

        magnetarA.burst{value: 0}(calls);
        assetA.approve(address(pearlmit), 0);

        uint256 ybBalanceAfter = yieldBox.balanceOf(userA, assetAId);
        assertGt(ybBalanceAfter, ybBalanceBefore);
    }


    function test_depositAddCollateralAndBorrowFromMarket_validation() public {
        address randomAddr = makeAddr("not_whitelisted");
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        DepositAddCollateralAndBorrowFromMarketData memory _params =
        _createDepositAddCollateralAndBorrowFromMarketData(
            randomAddr, address(marketHelper), address(this), 1 ether, 1 ether, true
        );
        bytes memory depositAddCollateralAndBorrowFromMarketData =
            abi.encodeWithSelector(MagnetarCollateralModule.depositAddCollateralAndBorrowFromMarket.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositAddCollateralAndBorrowFromMarketData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        // test marketHelper
        _params.market = address(magnetarA);
        _params.marketHelper = randomAddr;
        depositAddCollateralAndBorrowFromMarketData =
            abi.encodeWithSelector(MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector, _params);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositAddCollateralAndBorrowFromMarketData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);
    }

    
    function test_depositAddCollateralAndBorrowFromMarket_add_collateral_without_deposit_external_approvals() public {
        uint256 tokenAmount_ = 1 ether;
        {
            deal(address(collateralA), address(this), tokenAmount_);
        }

        DepositAddCollateralAndBorrowFromMarketData memory _params =
        _createDepositAddCollateralAndBorrowFromMarketData(
            address(sgl), address(marketHelper), address(this), tokenAmount_, 0, false
        );
        bytes memory depositAddCollateralAndBorrowFromMarketData =
            abi.encodeWithSelector(MagnetarCollateralModule.depositAddCollateralAndBorrowFromMarket.selector, _params);

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositAddCollateralAndBorrowFromMarketData
        });

        uint256 colSharesBefore = sgl._userCollateralShare(address(this));

        // manually deposit asset to YB
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(yieldBox), type(uint256).max);
        _setYieldBoxApproval(yieldBox, address(pearlmit));
        yieldBox.depositAsset(collateralAId, address(this), address(this), tokenAmount_, 0);
        collateralA.approve(address(yieldBox), 0);

        //approvals for add collateral
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = sgl._userCollateralShare(address(this));
        assertGt(colSharesAfter, colSharesBefore);
    }

    function test_depositAddCollateralAndBorrowFromMarket_deposit_and_add_collateral() public {
        uint256 tokenAmount_ = 1 ether;
        {
            deal(address(collateralA), address(this), tokenAmount_);
        }

        DepositAddCollateralAndBorrowFromMarketData memory _params =
        _createDepositAddCollateralAndBorrowFromMarketData(
            address(sgl), address(marketHelper), address(this), tokenAmount_, 0, true
        );
        bytes memory depositAddCollateralAndBorrowFromMarketData =
            abi.encodeWithSelector(MagnetarCollateralModule.depositAddCollateralAndBorrowFromMarket.selector, _params);

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositAddCollateralAndBorrowFromMarketData
        });

        uint256 colSharesBefore = sgl._userCollateralShare(address(this));

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = sgl._userCollateralShare(address(this));
        assertGt(colSharesAfter, colSharesBefore);
    }

    function test_depositAddCollateralAndBorrowFromMarket_deposit_add_collateral_and_borrow() public {
        uint256 tokenAmount_ = 1 ether;
        uint256 borrowAmount_ = 0.2 ether;

        {
            deal(address(collateralA), address(this), tokenAmount_);
            deal(address(assetA), address(this), tokenAmount_);

            depositAsset(assetA, assetAId, sgl, tokenAmount_);
        }

        DepositAddCollateralAndBorrowFromMarketData memory _params =
        _createDepositAddCollateralAndBorrowFromMarketData(
            address(sgl), address(marketHelper), address(this), tokenAmount_, borrowAmount_, true
        );
        bytes memory depositAddCollateralAndBorrowFromMarketData =
            abi.encodeWithSelector(MagnetarCollateralModule.depositAddCollateralAndBorrowFromMarket.selector, _params);

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositAddCollateralAndBorrowFromMarketData
        });

        uint256 colSharesBefore = sgl._userCollateralShare(address(this));
        uint256 borrowPartBefore = sgl._userBorrowPart(address(this));

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = sgl._userCollateralShare(address(this));
        uint256 borrowPartAfter = sgl._userBorrowPart(address(this));
        assertGt(colSharesAfter, colSharesBefore);
        assertGt(borrowPartAfter, borrowPartBefore);
    }

    function test_depositAddCollateralAndBorrowFromMarket_deposit_add_collateral_borrow_and_withdraw() public {
        uint256 tokenAmount_ = 1 ether;
        uint256 borrowAmount_ = 0.2 ether;

        {
            deal(address(collateralA), address(this), tokenAmount_);
            deal(address(assetA), address(this), tokenAmount_);

            depositAsset(assetA, assetAId, sgl, tokenAmount_);
        }

        DepositAddCollateralAndBorrowFromMarketData memory _params =
        _createDepositAddCollateralAndBorrowFromMarketData(
            address(sgl), address(marketHelper), address(this), tokenAmount_, borrowAmount_, true
        );
        _params.withdrawParams = MagnetarWithdrawData({
            yieldBox: address(yieldBox),
            assetId: assetAId,
            receiver: userA,
            amount: borrowAmount_,
            withdraw: true,
            unwrap: false,
            extractFromSender: false
        });
        bytes memory depositAddCollateralAndBorrowFromMarketData =
            abi.encodeWithSelector(MagnetarCollateralModule.depositAddCollateralAndBorrowFromMarket.selector, _params);

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.CollateralModule),
            target: address(magnetarA),
            value: 0,
            call: depositAddCollateralAndBorrowFromMarketData
        });

        uint256 colSharesBefore = sgl._userCollateralShare(address(this));
        uint256 borrowPartBefore = sgl._userBorrowPart(address(this));
        uint256 assetBalanceBefore = assetA.balanceOf(userA);

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = sgl._userCollateralShare(address(this));
        uint256 borrowPartAfter = sgl._userBorrowPart(address(this));
        uint256 assetBalanceAfter = assetA.balanceOf(userA);
        assertGt(colSharesAfter, colSharesBefore);
        assertGt(borrowPartAfter, borrowPartBefore);
        assertGt(assetBalanceAfter, assetBalanceBefore);
    }
}
