// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ERC20PermitApprovalMsg, ERC20PermitStruct} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarAction, MagnetarCall} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {MagnetarBaseTest, Magnetar} from "test/btt/MagnetarBaseTest.sol";
import {MagnetarStorage} from "contracts/Magnetar/MagnetarStorage.sol";

contract Magnetar_permitOperation is MagnetarBaseTest {
    function test_RevertWhen_TargetIsNotWhitelisted() external {
        // it should revert
        cluster.updateContract(0, address(aToeOFT), false);

        MagnetarCall[] memory magnetarCall = new MagnetarCall[](1);
        magnetarCall[0] = MagnetarCall({id: 0, target: address(aToeOFT), value: 0, call: hex""});
        vm.expectRevert(
            abi.encodeWithSelector(MagnetarStorage.Magnetar_TargetNotWhitelisted.selector, address(aToeOFT))
        );
        magnetar.burst(magnetarCall);
    }

    function test_RevertWhen_SelectorIsNotValid() external {
        // it should revert
        MagnetarCall[] memory magnetarCall = new MagnetarCall[](1);
        magnetarCall[0] = MagnetarCall({id: 0, target: address(aToeOFT), value: 0, call: hex""});
        vm.expectRevert(abi.encodeWithSelector(Magnetar.Magnetar_ActionNotValid.selector, 0, hex""));
        magnetar.burst(magnetarCall);
    }

    function test_WhenSelectorIsPermit() external {
        // it should work
        cluster.updateContract(0, address(this), true);
        ERC20PermitStruct memory permit_ =
            ERC20PermitStruct({owner: aliceAddr, spender: address(this), value: 1e18, nonce: 0, deadline: 1 days});

        bytes32 digest_ = aToeOFT.getTypedDataHash(permit_);
        ERC20PermitApprovalMsg memory permitApproval_ =
            getERC20PermitData(permit_, digest_, address(aToeOFT), alicePKey);

        aToeOFT.permit(
            permit_.owner,
            permit_.spender,
            permit_.value,
            permit_.deadline,
            permitApproval_.v,
            permitApproval_.r,
            permitApproval_.s
        );

        MagnetarCall[] memory magnetarCall = new MagnetarCall[](1);
        magnetarCall[0] = MagnetarCall({
            id: 0,
            target: address(aToeOFT),
            value: 0,
            call: abi.encodeWithSelector(
                aToeOFT.permit.selector,
                permit_.owner,
                permit_.spender,
                permit_.value,
                permit_.deadline,
                permitApproval_.v,
                permitApproval_.r,
                permitApproval_.s
                )
        });
        magnetar.burst(magnetarCall);
        assertEq(aToeOFT.allowance(aliceAddr, address(this)), 1e18);
    }

    function test_WhenSelectorIsRevoke() external {
        // it should work
    }

    function test_WhenSelectorIsPermitAll() external {
        // it should work
    }

    function test_WhenSelectorIsRevokeAll() external {
        // it should work
    }
}
