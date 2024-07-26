// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * Core
 */
import {TapiocaOmnichainEngineHelper} from "contracts/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {TapiocaOmnichainExtExec} from "contracts/tapiocaOmnichainEngine/extension/TapiocaOmnichainExtExec.sol";
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
import {ToeTokenReceiverMock} from "test/mocks/ToeTokenMock/ToeTokenReceiverMock.sol";
import {ToeTokenSenderMock} from "test/mocks/ToeTokenMock/ToeTokenSenderMock.sol";
import {ToeTokenMock} from "test/mocks/ToeTokenMock/ToeTokenMock.sol";
import {TestHelper} from "test/LZSetup/TestHelper.sol";

contract MagnetarBaseTest is TestHelper {
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
    TapiocaOmnichainExtExec public toeExtExec;
    IMagnetarHelper public magnetarHelper;
    Pearlmit public pearlmit;
    Cluster public cluster;

    // Tokens
    ToeTokenMock aToeOFT;
    ToeTokenMock bToeOFT;

    // Constants
    uint32 public EID_A = 1;
    address public ENDPOINT_A;

    uint32 public EID_B = 2;
    address public ENDPOINT_B;

    function setUp() public virtual override {
        vm.label(adminAddr, "admin");
        vm.label(aliceAddr, "alice");

        // Peripheral
        magnetarHelper = IMagnetarHelper(address(new MagnetarHelper()));
        pearlmit = new Pearlmit("Pearlmit", "1", adminAddr, 0);
        toeHelper = new TapiocaOmnichainEngineHelper();
        toeExtExec = new TapiocaOmnichainExtExec();
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

        // Lz setup

        setUpEndpoints(3, LibraryType.UltraLightNode);
        ENDPOINT_A = address(endpoints[EID_A]);
        ENDPOINT_B = address(endpoints[EID_B]);

        aToeOFT = new ToeTokenMock(
            address(endpoints[EID_A]),
            adminAddr,
            address(toeExtExec),
            address(
                new ToeTokenSenderMock(
                    "", "", address(endpoints[EID_A]), address(this), address(0), IPearlmit(address(pearlmit)), cluster
                )
            ),
            address(
                new ToeTokenReceiverMock(
                    "", "", address(endpoints[EID_A]), address(this), address(0), IPearlmit(address(pearlmit)), cluster
                )
            ),
            IPearlmit(address(pearlmit)),
            cluster
        );
    }
}
