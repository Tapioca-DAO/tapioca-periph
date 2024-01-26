// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.22;

import "forge-std/Test.sol";

// TODO Replace that by simple new Singularity when
contract ExternalContractLoader is Test {
    // SGL
    string constant SINGULARITY_ARTIFACT_PATH = "contracts/Bar/Singularity.sol";

    // YB
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
