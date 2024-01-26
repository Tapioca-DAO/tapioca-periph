// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.22;

// Tapioca
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {YieldBox} from "tapioca-periph/interfaces/periph/YieldBox.sol";
import {ExternalContractHelper} from "./ExternalContractHelper.sol";

import "forge-std/Test.sol";

contract BaseTest is Test {
    uint256 internal userAPKey = 0x1;
    address public userA = vm.addr(userAPKey);

    IYieldBox yieldbox;
    ISingularity ISingularity;

    function setUp() public {
        _initUsers();
    }

    function _initUsers() internal {
        vm.label(userA, "userA");
        vm.deal(userA, 1000 ether);
    }

    function _deployContract(bytes memory _contractBytecode, bytes memory _constructorArgs)
        internal
        returns (address addr)
    {
        bytes memory bytecode = bytes.concat(abi.encodePacked(_contractBytecode), _constructorArgs);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }
}
