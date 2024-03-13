// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/StdCheats.sol";
import "forge-std/StdAssertions.sol";
import "forge-std/StdUtils.sol";
import {TestBase} from "forge-std/Base.sol";

import "forge-std/console.sol";

import {Cluster} from "tapioca-periph/Cluster/Cluster.sol";

// Lz
import {TestHelper} from "../LZSetup/TestHelper.sol";

contract ClusterTest is TestBase, StdAssertions, StdCheats, StdUtils, TestHelper {
    Cluster cluster;

    uint32 aEid = 1;
    uint32 bEid = 2;

    /**
     * DEPLOY setup addresses
     */
    address __endpoint;
    uint256 __hostEid = aEid;
    address __owner = address(this);

    uint256 internal userAPKey = 0x1;
    uint256 internal userBPKey = 0x2;
    uint256 internal userCPKey = 0x3;
    address public userA = vm.addr(userAPKey);
    address public userB = vm.addr(userBPKey);
    address public userC = vm.addr(userCPKey);

    function setUp() public override {
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);
        vm.label(userA, "userA");
        vm.label(userB, "userB");
        setUpEndpoints(3, LibraryType.UltraLightNode);

        cluster = new Cluster(aEid, address(this));
    }

    function test_update_Eid() public {
        uint32 currentChainId = cluster.lzChainId();
        assertEq(currentChainId, aEid);

        cluster.updateLzChain(bEid);
        currentChainId = cluster.lzChainId();
        assertEq(currentChainId, bEid);
    }

    function test_update_whitelist_status() public {
        bool isWhitelisted = cluster.isWhitelisted(aEid, address(userC));
        assertFalse(isWhitelisted);

        cluster.updateContract(0, address(userC), true);
        isWhitelisted = cluster.isWhitelisted(aEid, address(userC));
        assertTrue(isWhitelisted);

        cluster.updateContract(aEid, address(userC), false);
        isWhitelisted = cluster.isWhitelisted(aEid, address(userC));
        assertFalse(isWhitelisted);
    }
}
