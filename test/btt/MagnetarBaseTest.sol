// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * Core
 */
import {TapiocaOmnichainEngineHelper} from "contracts/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {MagnetarCollateralModule} from "tapioca-periph/Magnetar/modules/MagnetarCollateralModule.sol";
import {MagnetarYieldBoxModule} from "contracts/Magnetar/modules/MagnetarYieldBoxModule.sol";
import {MagnetarOptionModule} from "contracts/Magnetar/modules/MagnetarOptionModule.sol";
import {MagnetarMintModule} from "contracts/Magnetar/modules/MagnetarMintModule.sol";
import {MagnetarBaseModule} from "contracts/Magnetar/modules/MagnetarBaseModule.sol";
import {IMagnetarHelper} from "contracts/interfaces/periph/IMagnetarHelper.sol";
import {MagnetarHelper} from "contracts/Magnetar/MagnetarHelper.sol";
import {Pearlmit, IPearlmit} from "contracts/pearlmit/Pearlmit.sol";
import {Cluster, ICluster} from "contracts/Cluster/Cluster.sol";
import {Magnetar} from "contracts/Magnetar/Magnetar.sol";

/**
 * Test
 */
import {MagnetarExtenderMock} from "test/mocks/MagnetarExtenderMock.sol";
import {Test} from "forge-std/Test.sol";

contract MagnetarBaseTest is Test {
    // Address mapping
    uint256 internal adminPKey = 0x1;
    address public adminAddr = vm.addr(adminPKey);
    uint256 internal alicePKey = 0x2;
    address public aliceAddr = vm.addr(alicePKey);

    // Core contracts
    Magnetar public magnetar;
    address payable collateralModule;
    address payable yieldBoxModule;
    address payable optionModule;
    address payable mintModule;

    // Peripheral contracts
    TapiocaOmnichainEngineHelper public toeHelper;
    MagnetarExtenderMock public magnetarExtender;
    IMagnetarHelper public magnetarHelper;
    Pearlmit public pearlmit;
    Cluster public cluster;

    function setUp() public {
        // Peripheral
        magnetarHelper = IMagnetarHelper(address(new MagnetarHelper()));
        pearlmit = new Pearlmit("Pearlmit", "1", adminAddr, 0);
        toeHelper = new TapiocaOmnichainEngineHelper();
        cluster = new Cluster(0, adminAddr);

        // Core
        collateralModule = payable(new MagnetarCollateralModule(IPearlmit(address(pearlmit)), address(toeHelper)));
        yieldBoxModule = payable(new MagnetarYieldBoxModule(IPearlmit(address(pearlmit)), address(toeHelper)));
        optionModule = payable(new MagnetarOptionModule(IPearlmit(address(pearlmit)), address(toeHelper)));
        mintModule = payable(new MagnetarMintModule(IPearlmit(address(pearlmit)), address(toeHelper)));
        magnetarExtender = new MagnetarExtenderMock();

        magnetar = new Magnetar(
            ICluster(address(cluster)),
            adminAddr,
            collateralModule,
            mintModule,
            optionModule,
            yieldBoxModule,
            IPearlmit(address(pearlmit)),
            address(toeHelper),
            magnetarHelper
        );

        // Setup
        vm.startPrank(adminAddr);
        cluster.updateContract(0, address(magnetar), true);
        vm.stopPrank();
    }
}
