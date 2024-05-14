// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {MagnetarTestHelper, MagnetarSetupData, TestBigBangData, TestSingularityData} from "./MagnetarTestHelper.sol";
import {
    MagnetarAction,
    MagnetarModule,
    MagnetarCall,
    MagnetarWithdrawData,
    DepositRepayAndRemoveCollateralFromMarketData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {MagnetarAssetModule} from "tapioca-periph/Magnetar/modules/MagnetarAssetModule.sol";

import {
    ERC20PermitStruct
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";

import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {IPermit} from "tapioca-periph/interfaces/common/IPermit.sol";


import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MagnetarAssetModuleTest is MagnetarTestHelper {
    
    // -----------------------
    //
    // Setup
    //
    // -----------------------
    function setUp() public override {
        createCommonSetup();
    }

    function _createDepositRepayAndRemoveCollateralFromMarketData(address market, address marketHelper, address user, uint256 depositAmount, uint256 repayAmount, uint256 collateralAmount) private returns(DepositRepayAndRemoveCollateralFromMarketData memory _params) {
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

    // -----------------------
    //
    // Tests
    //
    // -----------------------
    function test_depositRepayAndRemoveCollateralFromMarket_validation() public {
        address randomAddr = makeAddr("not_whitelisted");
        MagnetarCall[] memory calls = new MagnetarCall[](1);


        // test market
        DepositRepayAndRemoveCollateralFromMarketData memory _params = _createDepositRepayAndRemoveCollateralFromMarketData(randomAddr, address(marketHelper), address(this), 1 ether, 1 ether, 1 ether);
        bytes memory depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarAssetModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.AssetModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        // test marketHelper
        _params.market = address(magnetarA);
        _params.marketHelper = randomAddr;
        depositRepayAndRemoveCollateralFromMarketData = abi.encodeWithSelector(
            MagnetarAssetModule.depositRepayAndRemoveCollateralFromMarket.selector,
            _params
        );
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.AssetModule),
            target: address(magnetarA),
            value: 0,
            call: depositRepayAndRemoveCollateralFromMarketData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);
    }
}
