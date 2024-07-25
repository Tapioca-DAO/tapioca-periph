// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {
    MagnetarAction,
    MagnetarModule,
    MagnetarCall,
    IMagnetarModuleExtender
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {MagnetarBaseTest, Magnetar} from "test/btt/MagnetarBaseTest.sol";
import {MagnetarStorage} from "contracts/Magnetar/MagnetarStorage.sol";

contract Magnetar_burst is MagnetarBaseTest {
    function test_RevertWhen_CurrentAddressIsNotWhitelisted() external {
        // it should revert
        MagnetarCall[] memory magnetarCall = new MagnetarCall[](1);
        magnetarCall[0] = MagnetarCall({id: 0, target: address(0x1), value: 0, call: hex""});

        vm.prank(adminAddr);
        cluster.updateContract(0, address(magnetar), false);
        vm.expectRevert(
            abi.encodeWithSelector(MagnetarStorage.Magnetar_TargetNotWhitelisted.selector, address(magnetar))
        );
        magnetar.burst(magnetarCall);
    }

    function test_RevertWhen_Paused() external {
        // it should revert
        vm.prank(adminAddr);
        magnetar.setPause(true);

        MagnetarCall[] memory magnetarCall = new MagnetarCall[](1);
        magnetarCall[0] = MagnetarCall({id: 0, target: address(0x1), value: 0, call: hex""});

        vm.expectRevert("Pausable: paused");
        magnetar.burst(magnetarCall);
    }

    modifier whenCallingUsingMagnetarExtender() {
        vm.prank(adminAddr);
        magnetar.setMagnetarModuleExtender(IMagnetarModuleExtender(address(magnetarExtender)));
        _;
    }

    function test_RevertWhen_SuccessReturnsFalse() external whenCallingUsingMagnetarExtender {
        // it should revert
        MagnetarCall[] memory magnetarCall = new MagnetarCall[](1);
        magnetarCall[0] = MagnetarCall({id: 100, target: address(0x1), value: 0, call: hex""});

        vm.expectRevert("Invalid action id");
        magnetar.burst(magnetarCall);
    }

    function test_RevertWhen_ActionNotValid() external {
        // it should revert
        MagnetarCall[] memory magnetarCall = new MagnetarCall[](1);
        magnetarCall[0] = MagnetarCall({id: 50, target: address(0x1), value: 0, call: hex""});

        vm.expectRevert(abi.encodeWithSelector(Magnetar.Magnetar_ActionNotValid.selector, 50, hex""));
        magnetar.burst(magnetarCall);
    }

    function test_RevertWhen_MsgValueNotMatchingAccumulator() external {
        // it should revert
        vm.prank(adminAddr);
        magnetar.setMagnetarModuleExtender(IMagnetarModuleExtender(address(magnetarExtender)));

        MagnetarCall[] memory magnetarCall = new MagnetarCall[](1);
        magnetarCall[0] = MagnetarCall({id: 200, target: address(0x1), value: 0, call: hex""});

        vm.expectRevert(abi.encodeWithSelector(Magnetar.Magnetar_ValueMismatch.selector, 1e18, 0));
        magnetar.burst{value: 1e18}(magnetarCall);
    }
}
