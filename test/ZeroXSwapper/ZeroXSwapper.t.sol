// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/StdCheats.sol";
import "forge-std/StdAssertions.sol";
import "forge-std/StdUtils.sol";
import {TestBase} from "forge-std/Base.sol";

import "forge-std/console.sol";

import {IZeroXSwapper} from "tapioca-periph/interfaces/periph/IZeroXSwapper.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {ZerroXSwapperMockTarget} from "./ZerroXSwapperMockTarget.sol";
import {ZeroXSwapper} from "tapioca-periph/Swapper/ZeroXSwapper.sol";
import {Cluster} from "tapioca-periph/Cluster/Cluster.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

// Lz
import {TestHelper} from "../LZSetup/TestHelper.sol";

// External
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ZeroXSwapperTest is TestBase, StdAssertions, StdCheats, StdUtils, TestHelper {
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

    ERC20Mock aERC20;
    ERC20Mock bERC20;

    ZerroXSwapperMockTarget swapperTarget;
    ZeroXSwapper swapper;
    Cluster cluster;

    // address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function setUp() public override {
        // uint256 mainnetBlock = 19_000_000;
        // vm.createSelectFork(getChain("ethereum").rpcUrl, mainnetBlock);
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);
        vm.label(userA, "userA");
        vm.label(userB, "userB");
        setUpEndpoints(3, LibraryType.UltraLightNode);

        aERC20 = new ERC20Mock();
        bERC20 = new ERC20Mock();

        cluster = new Cluster(aEid, address(this));
        swapperTarget = new ZerroXSwapperMockTarget();
        swapper = new ZeroXSwapper(address(swapperTarget), ICluster(address(cluster)), address(this));
    }

    function test_0x_constructor() public {
        assertEq(address(swapper.cluster()), address(cluster));
        assertEq(swapper.zeroXProxy(), address(swapperTarget));
        assertEq(swapper.owner(), address(this));
    }

    function test_0x_swap() public {
        uint256 amount = 1 ether;

        // setup
        {
            deal(address(aERC20), address(this), amount);
            deal(address(bERC20), address(swapper), amount);
            assertEq(bERC20.balanceOf(address(swapper)), amount);
        }

        IZeroXSwapper.SZeroXSwapData memory swapData = IZeroXSwapper.SZeroXSwapData({
            sellToken: IERC20(address(aERC20)),
            buyToken: IERC20(address(bERC20)),
            swapTarget: payable(swapperTarget),
            swapCallData: abi.encodeWithSelector(ZerroXSwapperMockTarget.toggleState.selector)
        });

        cluster.updateContract(0, address(this), true);

        aERC20.approve(address(swapper), type(uint256).max);
        swapper.swap(swapData, amount, amount);

        assertEq(bERC20.balanceOf(address(this)), amount);
        assertEq(bERC20.balanceOf(address(swapper)), 0);
    }
}
