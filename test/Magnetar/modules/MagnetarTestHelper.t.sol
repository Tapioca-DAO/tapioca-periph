// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Lz
import {TestHelper} from "tap-utils/../test/LZSetup/TestHelper.sol";

// External
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TapiocaOmnichainEngineHelper} from
    "tap-utils/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {SimpleLeverageExecutor} from "tapioca-bar/markets/leverage/SimpleLeverageExecutor.sol";
import {SGLInterestHelper} from "tapioca-bar/markets/singularity/SGLInterestHelper.sol";
import {ERC20WithoutStrategy} from "yieldbox/strategies/ERC20WithoutStrategy.sol";
import {SGLLiquidation} from "tapioca-bar/markets/singularity/SGLLiquidation.sol";
import {SGLCollateral} from "tapioca-bar/markets/singularity/SGLCollateral.sol";
import {SGLLeverage} from "tapioca-bar/markets/singularity/SGLLeverage.sol";
import {Singularity} from "tapioca-bar/markets/singularity/Singularity.sol";
import {SGLBorrow} from "tapioca-bar/markets/singularity/SGLBorrow.sol";
import {Cluster} from "tap-utils/Cluster/Cluster.sol";

import {BBLiquidation} from "tapioca-bar/markets/bigBang/BBLiquidation.sol";
import {BBCollateral} from "tapioca-bar/markets/bigBang/BBCollateral.sol";
import {BBLeverage} from "tapioca-bar/markets/bigBang/BBLeverage.sol";
import {BBBorrow} from "tapioca-bar/markets/bigBang/BBBorrow.sol";
import {BigBang} from "tapioca-bar/markets/bigBang/BigBang.sol";
import {BBDebtRateHelper} from "tapioca-bar/markets/bigBang/BBDebtRateHelper.sol";

import {MagnetarCollateralModule} from "tapioca-periph/Magnetar/modules/MagnetarCollateralModule.sol";
import {ITapiocaOmnichainEngine} from "tap-utils/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarYieldBoxModule} from "tapioca-periph/Magnetar/modules/MagnetarYieldBoxModule.sol";
import {MagnetarOptionModule} from "tapioca-periph/Magnetar/modules/MagnetarOptionModule.sol";
import {MagnetarMintModule} from "tapioca-periph/Magnetar/modules/MagnetarMintModule.sol";
import {MagnetarBaseModule} from "tapioca-periph/Magnetar/modules/MagnetarBaseModule.sol";
import {Magnetar} from "tapioca-periph/Magnetar/Magnetar.sol";

import {IMagnetarHelper} from "tap-utils/interfaces/periph/IMagnetarHelper.sol";
import {MagnetarHelper} from "tapioca-periph/Magnetar/MagnetarHelper.sol";
import {MarketHelper} from "tapioca-bar/markets/MarketHelper.sol";

import {UsdoInitStruct, UsdoModulesInitStruct, IUsdo} from "tap-utils/interfaces/oft/IUsdo.sol";
import {UsdoMarketReceiverModule} from "tapioca-bar/usdo/modules/UsdoMarketReceiverModule.sol";
import {UsdoOptionReceiverModule} from "tapioca-bar/usdo/modules/UsdoOptionReceiverModule.sol";
import {UsdoReceiver} from "tapioca-bar/usdo/modules/UsdoReceiver.sol";
import {UsdoSender} from "tapioca-bar/usdo/modules/UsdoSender.sol";
import {Usdo, BaseUsdo} from "tapioca-bar/usdo/Usdo.sol";

import {ITOFT, TOFTInitStruct, TOFTModulesInitStruct} from "tap-utils/interfaces/oft/ITOFT.sol";
import {TOFTOptionsReceiverModule} from "tapiocaz/tOFT/modules/TOFTOptionsReceiverModule.sol";
import {TOFTMarketReceiverModule} from "tapiocaz/tOFT/modules/TOFTMarketReceiverModule.sol";
import {TOFTGenericReceiverModule} from "tapiocaz/tOFT/modules/TOFTGenericReceiverModule.sol";
import {BaseTOFTReceiver} from "tapiocaz/tOFT/modules/BaseTOFTReceiver.sol";
import {mTOFTReceiver} from "tapiocaz/tOFT/modules/mTOFTReceiver.sol";
import {TOFTMsgCodec} from "tapiocaz/tOFT/libraries/TOFTMsgCodec.sol";
import {TOFTReceiver} from "tapiocaz/tOFT/modules/TOFTReceiver.sol";
import {TOFTSender} from "tapiocaz/tOFT/modules/TOFTSender.sol";
import {TOFTVault} from "tapiocaz/tOFT/TOFTVault.sol";
import {BaseTOFT} from "tapiocaz/tOFT/BaseTOFT.sol";
import {mTOFT} from "tapiocaz/tOFT/mTOFT.sol";
import {TOFT} from "tapiocaz/tOFT/TOFT.sol";

import {ILeverageExecutor} from "tap-utils/interfaces/bar/ILeverageExecutor.sol";
import {ITapiocaOracle} from "tap-utils/interfaces/periph/ITapiocaOracle.sol";
import {IZeroXSwapper} from "tap-utils/interfaces/periph/IZeroXSwapper.sol";
import {IERC20} from "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import {ZerroXSwapperMockTarget} from "tap-utils/../test/ZeroXSwapper/ZerroXSwapperMockTarget.sol";
import {ZeroXSwapper} from "tap-utils/Swapper/ZeroXSwapper.sol";

import {OracleMock} from "../../mocks/OracleMock.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

import {ICluster} from "tap-utils/interfaces/periph/ICluster.sol";
import {Cluster} from "tap-utils/Cluster/Cluster.sol";

import {Pearlmit, IPearlmit, PearlmitHash} from "tap-utils/pearlmit/Pearlmit.sol";
import {IPearlmit} from "tap-utils/interfaces/periph/IPearlmit.sol";

import {IWrappedNative} from "yieldbox/interfaces/IWrappedNative.sol";
import {YieldBoxURIBuilder} from "yieldbox/YieldBoxURIBuilder.sol";
import {TokenType} from "yieldbox/enums/YieldBoxTokenType.sol";
import {IStrategy} from "yieldbox/interfaces/IStrategy.sol";
import {IYieldBox} from "yieldbox/interfaces/IYieldBox.sol";
import {YieldBox} from "yieldbox/YieldBox.sol";

import {IPenrose} from "tap-utils/interfaces/bar/IPenrose.sol";
import {Penrose} from "tapioca-bar/Penrose.sol";

import {TapiocaOmnichainExtExec} from "tap-utils/tapiocaOmnichainEngine/extension/TapiocaOmnichainExtExec.sol";

import {IMarket, Module} from "tap-utils/interfaces/bar/IMarket.sol";

import {ERC20PermitStruct} from "tap-utils/interfaces/periph/ITapiocaOmnichainEngine.sol";

import {MagnetarWithdrawData} from "tap-utils/interfaces/periph/IMagnetar.sol";
import {SGLInit} from "tapioca-bar/markets/singularity/SGLInit.sol";

import "forge-std/Test.sol";

struct TestSingularityData {
    address penrose;
    address asset;
    uint256 assetId;
    address collateral;
    uint256 collateralId;
    ITapiocaOracle oracle;
    ILeverageExecutor leverageExecutor;
}

struct TestBigBangData {
    address penrose;
    address collateral;
    uint256 collateralId;
    ITapiocaOracle oracle;
    ILeverageExecutor leverageExecutor;
    uint256 debtRateAgainstEth;
    uint256 debtRateMin;
    uint256 debtRateMax;
}

struct MagnetarSetupData {
    MagnetarCollateralModule collateralModule;
    MagnetarMintModule mintModule;
    MagnetarOptionModule optionModule;
    MagnetarYieldBoxModule yieldBoxModule;
}

contract MagnetarTestHelper is TestHelper {
    Cluster clusterA;
    Cluster clusterB;
    Pearlmit pearlmit;
    Magnetar magnetarA;
    Magnetar magnetarB;
    MagnetarHelper magnetarHelper;
    OracleMock oracle;
    MarketHelper marketHelper;

    YieldBox yieldBox;
    Penrose penrose;
    Singularity sglMC;
    BigBang bbMC;

    SGLInit sglInit;
    Singularity sgl;
    BigBang bb;

    uint32 aEid = 1;
    uint32 bEid = 2;

    ERC20Mock aERC20;
    ERC20Mock bERC20;
    ERC20Mock collateralErc20;
    ERC20Mock weth;
    ERC20Mock tap;

    Usdo assetA;
    TOFT collateralA;
    uint256 assetAId;
    uint256 collateralAId;

    Usdo assetB;
    TOFT collateralB;
    uint256 assetBId;
    uint256 collateralBId;

    uint256 wethId;
    uint256 tapId;

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

    function createCommonSetup() public {
        setUpEndpoints(3, LibraryType.UltraLightNode);

        aERC20 = new ERC20Mock();
        bERC20 = new ERC20Mock();
        collateralErc20 = new ERC20Mock();
        weth = new ERC20Mock();
        tap = new ERC20Mock();

        clusterA = new Cluster(aEid, address(this));
        clusterB = new Cluster(bEid, address(this));
        pearlmit = new Pearlmit("Test", "1", address(this), 0);

        magnetarA = createMagnetar(address(clusterA), address(pearlmit));
        magnetarB = createMagnetar(address(clusterB), address(pearlmit));

        magnetarHelper = new MagnetarHelper();
        marketHelper = new MarketHelper();
        oracle = new OracleMock("Test", "TT", 1 ether);

        magnetarA.setHelper(address(magnetarHelper));
        magnetarB.setHelper(address(magnetarHelper));

        yieldBox = createYieldBox(address(weth), pearlmit);

        ERC20WithoutStrategy wethStrategy = createYieldBoxEmptyStrategy(address(yieldBox), address(weth));
        ERC20WithoutStrategy tapStrategy = createYieldBoxEmptyStrategy(address(yieldBox), address(tap));
        wethId = registerYieldBoxAsset(address(yieldBox), address(weth), address(wethStrategy));
        tapId = registerYieldBoxAsset(address(yieldBox), address(weth), address(wethStrategy));

        sglInit = new SGLInit();
        (penrose, sglMC, bbMC) = createPenrose(
            address(pearlmit),
            address(yieldBox),
            address(clusterA),
            address(tap),
            address(weth),
            tapId,
            wethId,
            address(this)
        );

        // crete USDO
        TapiocaOmnichainExtExec extExec = new TapiocaOmnichainExtExec();
        assetA = createUsdo(address(yieldBox), address(clusterA), address(extExec), address(pearlmit), aEid);
        assetB = createUsdo(address(yieldBox), address(clusterB), address(extExec), address(pearlmit), bEid);

        // create TOFT
        collateralA = createTOFT(
            address(yieldBox),
            address(clusterA),
            address(collateralErc20),
            address(extExec),
            address(pearlmit),
            aEid,
            aEid
        );
        collateralB = createTOFT(
            address(yieldBox),
            address(clusterB),
            address(collateralErc20),
            address(extExec),
            address(pearlmit),
            bEid,
            aEid
        );

        ERC20WithoutStrategy assetAStrategy = createYieldBoxEmptyStrategy(address(yieldBox), address(assetA));
        ERC20WithoutStrategy assetBStrategy = createYieldBoxEmptyStrategy(address(yieldBox), address(assetB));
        ERC20WithoutStrategy collateralAStrategy = createYieldBoxEmptyStrategy(address(yieldBox), address(collateralA));
        ERC20WithoutStrategy collateralBStrategy = createYieldBoxEmptyStrategy(address(yieldBox), address(collateralB));
        assetAId = registerYieldBoxAsset(address(yieldBox), address(assetA), address(assetAStrategy));
        collateralAId = registerYieldBoxAsset(address(yieldBox), address(collateralA), address(collateralAStrategy));
        assetBId = registerYieldBoxAsset(address(yieldBox), address(assetB), address(assetBStrategy));
        collateralBId = registerYieldBoxAsset(address(yieldBox), address(collateralB), address(collateralBStrategy));

        penrose.setUsdoToken(address(assetA), assetAId);

        sgl = createSingularity(
            TestSingularityData(
                address(penrose),
                address(assetA),
                assetAId,
                address(collateralA),
                collateralAId,
                ITapiocaOracle(address(oracle)),
                ILeverageExecutor(address(0))
            ),
            address(sglMC)
        );
        bb = createBigBang(
            TestBigBangData(
                address(penrose),
                address(collateralA),
                collateralAId,
                ITapiocaOracle(address(oracle)),
                ILeverageExecutor(address(0)),
                0,
                0,
                0
            ),
            address(bbMC)
        );
        setAssetOracle(penrose, bb, address(oracle));
       
        address[] memory markets = new address[](1);
        markets[0] = address(bb);
        bytes[] memory marketsData = new bytes[](1);
        BBDebtRateHelper bbRateHelper = new BBDebtRateHelper();
        marketsData[0] = abi.encodeWithSelector(BigBang.setDebtRateHelper.selector, address(bbRateHelper));
        penrose.executeMarketFn(markets, marketsData, true);

        assetA.setMinterStatus(address(bb), true);
        assetA.setBurnerStatus(address(bb), true);

        clusterA.setRoleForContract(address(magnetarA), keccak256("MAGNETAR_CALLEE"), true);
        clusterA.setRoleForContract(address(magnetarA), keccak256("MAGNETAR_CONTRACT"), true);
        clusterA.setRoleForContract(address(magnetarHelper), keccak256("MAGNETAR_HELPER_CALLEE"), true);
        clusterA.setRoleForContract(address(yieldBox), keccak256("MAGNETAR_YIELDBOX_CALLEE"), true);
        clusterA.setRoleForContract(address(yieldBox), keccak256("YIELDBOX_WITHDRAW"), true);
        clusterA.setRoleForContract(address(sgl), keccak256("MAGNETAR_MARKET_CALLEE"), true);
        clusterA.setRoleForContract(address(bb), keccak256("MAGNETAR_MARKET_CALLEE"), true);
        clusterA.setRoleForContract(address(marketHelper), keccak256("MAGNETAR_HELPER_CALLEE"), true);
        clusterA.setRoleForContract(address(assetA), keccak256("MAGNETAR_PERMIT_CALLEE"), true);
        clusterA.setRoleForContract(address(collateralA), keccak256("MAGNETAR_PERMIT_CALLEE"), true);

        clusterB.setRoleForContract(address(magnetarB), keccak256("MAGNETAR_CALLEE"), true);
        clusterB.setRoleForContract(address(magnetarB), keccak256("MAGNETAR_CONTRACT"), true);
        clusterB.setRoleForContract(address(magnetarHelper), keccak256("MAGNETAR_HELPER_CALLEE"), true);
        clusterB.setRoleForContract(address(yieldBox), keccak256("MAGNETAR_YIELDBOX_CALLEE"), true);
        clusterB.setRoleForContract(address(yieldBox), keccak256("YIELDBOX_WITHDRAW"), true);
        clusterB.setRoleForContract(address(sgl), keccak256("MAGNETAR_MARKET_CALLEE"), true);
        clusterB.setRoleForContract(address(bb), keccak256("MAGNETAR_MARKET_CALLEE"), true);
        clusterB.setRoleForContract(address(marketHelper), keccak256("MAGNETAR_HELPER_CALLEE"), true);
        clusterB.setRoleForContract(address(assetB), keccak256("MAGNETAR_PERMIT_CALLEE"), true);
        clusterB.setRoleForContract(address(collateralB), keccak256("MAGNETAR_PERMIT_CALLEE"), true);

        // TODO: refactor after `bar` updates
        clusterA.updateContract(0, address(magnetarA), true);
        clusterA.updateContract(0, address(magnetarHelper), true);
        clusterA.updateContract(0, address(oracle), true);
        clusterA.updateContract(0, address(pearlmit), true);
        clusterA.updateContract(0, address(assetA), true);
        clusterA.updateContract(0, address(collateralA), true);
        clusterA.updateContract(0, address(marketHelper), true);
        clusterA.updateContract(bEid, address(assetB), true);
        clusterA.updateContract(bEid, address(collateralB), true);
        clusterA.updateContract(0, address(penrose), true);
        clusterA.updateContract(0, address(yieldBox), true);
        clusterA.updateContract(0, address(sgl), true);
        clusterA.updateContract(0, address(bb), true);

        clusterB.updateContract(0, address(magnetarB), true);
        clusterB.updateContract(0, address(magnetarHelper), true);
        clusterB.updateContract(0, address(oracle), true);
        clusterB.updateContract(0, address(pearlmit), true);
        clusterB.updateContract(0, address(assetB), true);
        clusterB.updateContract(0, address(collateralB), true);
        clusterB.updateContract(0, address(marketHelper), true);
        clusterB.updateContract(aEid, address(assetA), true);
        clusterB.updateContract(aEid, address(collateralA), true);
        clusterB.updateContract(0, address(penrose), true);
        clusterB.updateContract(0, address(yieldBox), true);
        clusterB.updateContract(0, address(sgl), true);
        clusterB.updateContract(0, address(bb), true);

        vm.label(address(magnetarA), "Magnetar A");
        vm.label(address(magnetarB), "Magnetar B");
        vm.label(address(magnetarHelper), "MagnetarHelper");
        vm.label(address(oracle), "Oracle");
        vm.label(address(assetA), "Usdo (asset) A");
        vm.label(address(collateralA), "Collateral (TOFT) A");
        vm.label(address(assetB), "Usdo (asset) B");
        vm.label(address(collateralB), "Collateral (TOFT) B");
        vm.label(address(aERC20), "aERC20");
        vm.label(address(bERC20), "bERC20");
        vm.label(address(collateralErc20), "collateralErc20");
        vm.label(address(weth), "WETH");
        vm.label(address(tap), "TapToken");
        vm.label(address(marketHelper), "MarketHelper");
        vm.label(address(clusterA), "Cluster A");
        vm.label(address(clusterB), "Cluster B");
    }
    // -----------------------
    //
    // Setup helpers
    //
    // -----------------------

    function createTOFT(
        address yieldBox,
        address cluster,
        address erc20,
        address extExec,
        address pearlmit,
        uint32 endointId,
        uint32 hostEid
    ) public returns (TOFT toft) {
        TOFTVault toftVault = new TOFTVault(address(erc20));
        TOFTInitStruct memory toftInitStruct = TOFTInitStruct({
            name: "Token TOFT",
            symbol: "TOFTTKN",
            endpoint: address(endpoints[endointId]),
            delegate: address(this), // owner
            yieldBox: yieldBox,
            cluster: cluster,
            erc20: erc20,
            vault: address(toftVault),
            hostEid: hostEid,
            extExec: extExec,
            pearlmit: IPearlmit(pearlmit)
        });

        {
            TOFTSender toftSender = new TOFTSender(toftInitStruct);
            mTOFTReceiver toftReceiver = new mTOFTReceiver(toftInitStruct);
            TOFTMarketReceiverModule toftMarketReceiverModule = new TOFTMarketReceiverModule(toftInitStruct);
            TOFTOptionsReceiverModule toftOptionsReceiverModule = new TOFTOptionsReceiverModule(toftInitStruct);
            TOFTGenericReceiverModule toftGenericReceiverModule = new TOFTGenericReceiverModule(toftInitStruct);
            vm.label(address(toftSender), "toftSender");
            vm.label(address(toftReceiver), "toftReceiver");
            vm.label(address(toftMarketReceiverModule), "toftMarketReceiverModule");
            vm.label(address(toftOptionsReceiverModule), "toftOptionsReceiverModule");
            vm.label(address(toftGenericReceiverModule), "toftGenericReceiverModule");
            TOFTModulesInitStruct memory toftModulesInitStruct = TOFTModulesInitStruct({
                tOFTSenderModule: address(toftSender),
                tOFTReceiverModule: address(toftReceiver),
                marketReceiverModule: address(toftMarketReceiverModule),
                optionsReceiverModule: address(toftOptionsReceiverModule),
                genericReceiverModule: address(toftGenericReceiverModule)
            });
            toft =
                TOFT(payable(_deployOApp(type(TOFT).creationCode, abi.encode(toftInitStruct, toftModulesInitStruct))));
        }
    }

    function createUsdo(address yieldBox, address cluster, address extExec, address pearlmit, uint32 endointId)
        public
        returns (Usdo usdo)
    {
        UsdoInitStruct memory usdoInitStruct = UsdoInitStruct({
            endpoint: address(endpoints[endointId]),
            delegate: __owner,
            yieldBox: yieldBox,
            cluster: cluster,
            extExec: extExec,
            pearlmit: IPearlmit(pearlmit)
        });
        UsdoSender usdoSender = new UsdoSender(usdoInitStruct);
        UsdoReceiver usdoReceiver = new UsdoReceiver(usdoInitStruct);
        UsdoMarketReceiverModule usdoMarketReceiverModule = new UsdoMarketReceiverModule(usdoInitStruct);
        UsdoOptionReceiverModule usdoOptionsReceiverModule = new UsdoOptionReceiverModule(usdoInitStruct);
        vm.label(address(usdoSender), "usdoSender");
        vm.label(address(usdoReceiver), "usdoReceiver");
        vm.label(address(usdoMarketReceiverModule), "usdoMarketReceiverModule");
        vm.label(address(usdoOptionsReceiverModule), "usdoOptionsReceiverModule");
        UsdoModulesInitStruct memory usdoModulesInitStruct = UsdoModulesInitStruct({
            usdoSenderModule: address(usdoSender),
            usdoReceiverModule: address(usdoReceiver),
            marketReceiverModule: address(usdoMarketReceiverModule),
            optionReceiverModule: address(usdoOptionsReceiverModule)
        });
        usdo = Usdo(payable(_deployOApp(type(Usdo).creationCode, abi.encode(usdoInitStruct, usdoModulesInitStruct))));
    }

    function createYieldBox(address weth, Pearlmit pearlmit) public returns (YieldBox yb) {
        YieldBoxURIBuilder ybUri = new YieldBoxURIBuilder();
        yb = new YieldBox(IWrappedNative(weth), ybUri, pearlmit, address(this));
    }

    function setBBEthMarket(Penrose penrose, address market) external {
        penrose.setBigBangEthMarket(market);
    }

    function createMagnetar(address _cluster, address _pearlmit) public returns (Magnetar magnetar) {
        TapiocaOmnichainEngineHelper toeHelper = new TapiocaOmnichainEngineHelper();

        MagnetarSetupData memory setup;
        setup.collateralModule = new MagnetarCollateralModule(IPearlmit(_pearlmit), address(toeHelper));
        setup.mintModule = new MagnetarMintModule(IPearlmit(_pearlmit), address(toeHelper));
        setup.optionModule = new MagnetarOptionModule(IPearlmit(_pearlmit), address(toeHelper));
        setup.yieldBoxModule = new MagnetarYieldBoxModule(IPearlmit(_pearlmit), address(toeHelper));

        magnetar = new Magnetar(
            ICluster(_cluster),
            address(this),
            payable(setup.collateralModule),
            payable(setup.mintModule),
            payable(setup.optionModule),
            payable(setup.yieldBoxModule),
            IPearlmit(_pearlmit),
            address(toeHelper),
            IMagnetarHelper(address(new MagnetarHelper()))
        );
    }

    function createPenrose(
        address pearlmit,
        address _yieldBox,
        address _cluster,
        address tapToken_,
        address mainToken_,
        uint256 tapTokenId_,
        uint256 mainTokenId_,
        address owner
    ) public returns (Penrose penrose, Singularity mediumRiskMC, BigBang bbMediumRiskMC) {
        penrose = new Penrose(
            IYieldBox(_yieldBox),
            ICluster(_cluster),
            IERC20(tapToken_),
            IERC20(mainToken_),
            IPearlmit(pearlmit),
            tapTokenId_,
            mainTokenId_,
            owner
        );
        mediumRiskMC = new Singularity();
        bbMediumRiskMC = new BigBang();

        penrose.registerSingularityMasterContract(address(mediumRiskMC), IPenrose.ContractType.mediumRisk);
        penrose.registerBigBangMasterContract(address(bbMediumRiskMC), IPenrose.ContractType.mediumRisk);
    }

    function setAssetOracle(Penrose penrose, BigBang bb, address oracle) public {
        // function executeMarketFn(address[] calldata mc, bytes[] memory data, bool forceSuccess)
        address[] memory markets = new address[](1);
        markets[0] = address(bb);
        bytes[] memory marketsData = new bytes[](1);
        marketsData[0] = abi.encodeWithSelector(BigBang.setAssetOracle.selector, oracle, "0x");

        penrose.executeMarketFn(markets, marketsData, true);
    }

    function registerYieldBoxAsset(address _yieldBox, address _token, address _strategy) public returns (uint256) {
        return YieldBox(_yieldBox).registerAsset(TokenType.ERC20, _token, IStrategy(_strategy), 0);
    }

    function createYieldBoxEmptyStrategy(address _yieldBox, address _erc20) public returns (ERC20WithoutStrategy) {
        return new ERC20WithoutStrategy(IYieldBox(_yieldBox), IERC20(_erc20));
    }

    function createBigBang(TestBigBangData memory _bb, address _mc) public returns (BigBang) {
        BigBang bb = new BigBang();

        (
            BigBang._InitMemoryModulesData memory initModulesData,
            BigBang._InitMemoryDebtData memory initDebtData,
            BigBang._InitMemoryData memory initMemoryData
        ) = _getBigBangInitData(_bb);

        {
            bb.init(abi.encode(initModulesData, initDebtData, initMemoryData));
        }

        {
            Penrose(_bb.penrose).addBigBang(_mc, address(bb));
        }

        return bb;
    }

    function createSingularity(TestSingularityData memory _sgl, address _mc) public returns (Singularity) {
        Singularity sgl = new Singularity();
        (
            Singularity._InitMemoryModulesData memory _modulesData,
            Singularity._InitMemoryTokensData memory _tokensData,
            Singularity._InitMemoryData memory _data
        ) = _getSingularityInitData(_sgl);
        {
            sgl.init(address(sglInit), abi.encode(_modulesData, _tokensData, _data));
        }

        {
            Penrose(_sgl.penrose).addSingularity(_mc, address(sgl));
        }

        {
            SGLInterestHelper sglInterestHelper = new SGLInterestHelper();

            bytes memory payload = abi.encodeWithSelector(
                Singularity.setSingularityConfig.selector,
                sgl.borrowOpeningFee(),
                0,
                0,
                0,
                0,
                0,
                0,
                address(sglInterestHelper),
                0
            );
            address[] memory mc = new address[](1);
            mc[0] = address(sgl);

            bytes[] memory data = new bytes[](1);
            data[0] = payload;
            Penrose(_sgl.penrose).executeMarketFn(mc, data, false);
        }

        return sgl;
    }

    function _getBigBangInitData(TestBigBangData memory _bb)
        private
        returns (
            BigBang._InitMemoryModulesData memory modulesData,
            BigBang._InitMemoryDebtData memory debtData,
            BigBang._InitMemoryData memory data
        )
    {
        BBLiquidation bbLiq = new BBLiquidation();
        BBBorrow bbBorrow = new BBBorrow();
        BBCollateral bbCollateral = new BBCollateral();
        BBLeverage bbLev = new BBLeverage();

        modulesData =
            BigBang._InitMemoryModulesData(address(bbLiq), address(bbBorrow), address(bbCollateral), address(bbLev));

        debtData = BigBang._InitMemoryDebtData(_bb.debtRateAgainstEth, _bb.debtRateMin, _bb.debtRateMax);

        data = BigBang._InitMemoryData(
            IPenrose(_bb.penrose),
            IERC20(_bb.collateral),
            _bb.collateralId,
            ITapiocaOracle(address(_bb.oracle)),
            0,
            75000,
            80000,
            _bb.leverageExecutor
        );
    }

    function _getSingularityInitData(TestSingularityData memory _sgl)
        private
        returns (
            Singularity._InitMemoryModulesData memory modulesData,
            Singularity._InitMemoryTokensData memory tokensData,
            Singularity._InitMemoryData memory data
        )
    {
        SGLLiquidation sglLiq = new SGLLiquidation();
        SGLBorrow sglBorrow = new SGLBorrow();
        SGLCollateral sglCollateral = new SGLCollateral();
        SGLLeverage sglLev = new SGLLeverage();

        modulesData = Singularity._InitMemoryModulesData(
            address(sglLiq), address(sglBorrow), address(sglCollateral), address(sglLev)
        );

        tokensData = Singularity._InitMemoryTokensData(
            IERC20(_sgl.asset), _sgl.assetId, IERC20(_sgl.collateral), _sgl.collateralId
        );

        data = Singularity._InitMemoryData(
            IPenrose(_sgl.penrose), ITapiocaOracle(address(_sgl.oracle)), 0, 75000, 80000, _sgl.leverageExecutor
        );
    }

    // -----------------------
    //
    // Market helpers
    //
    // -----------------------
    function createEmptyWithdrawData() public returns (MagnetarWithdrawData memory) {
        return MagnetarWithdrawData({
            yieldBox: address(0),
            assetId: 0,
            receiver: address(this),
            amount: 1 ether,
            withdraw: false,
            unwrap: false,
            extractFromSender: false
        });
    }

    function depositAsset(Usdo _asset, uint256 _assetId, Singularity _sgl, uint256 amount) public {
        deal(address(_asset), address(this), amount);
        _asset.approve(address(yieldBox), type(uint256).max);
        _asset.approve(address(pearlmit), type(uint256).max);
        _setYieldBoxApproval(yieldBox, address(_sgl));
        _setYieldBoxApproval(yieldBox, address(pearlmit));
        pearlmit.approve(1155, address(yieldBox), _assetId, address(_sgl), type(uint200).max, uint48(block.timestamp));

        uint256 share = yieldBox.toShare(_assetId, amount, false);
        yieldBox.depositAsset(_assetId, address(this), address(this), 0, share);
        _sgl.addAsset(address(this), address(this), false, share);
        _setYieldBoxRevoke(yieldBox, address(_sgl));
        _setYieldBoxRevoke(yieldBox, address(pearlmit));
    }

    function depositCollateral(TOFT _collateral, uint256 _collateralId, Singularity _sgl, uint256 amount) public {
        deal(address(_collateral), address(this), amount);
        _collateral.approve(address(yieldBox), type(uint256).max);
        _collateral.approve(address(pearlmit), type(uint256).max);
        _setYieldBoxApproval(yieldBox, address(_sgl));
        _setYieldBoxApproval(yieldBox, address(pearlmit));
        pearlmit.approve(
            1155, address(yieldBox), _collateralId, address(_sgl), type(uint200).max, uint48(block.timestamp)
        );

        uint256 share = yieldBox.toShare(_collateralId, amount, false);
        yieldBox.depositAsset(_collateralId, address(this), address(this), 0, share);

        (Module[] memory modules, bytes[] memory calls) =
            marketHelper.addCollateral(address(this), address(this), false, 0, share);
        _sgl.execute(modules, calls, true);
        _setYieldBoxRevoke(yieldBox, address(_sgl));
        _setYieldBoxRevoke(yieldBox, address(pearlmit));
    }

    function borrow(Singularity _sgl, uint256 amount, bool expectRevert) public {
        (Module[] memory modules, bytes[] memory calls) = marketHelper.borrow(address(this), address(this), amount);

        if (expectRevert) vm.expectRevert();
        _sgl.execute(modules, calls, true);
    }

    function repay(uint256 part, uint256 _assetId, Singularity _sgl) public {
        pearlmit.approve(1155, address(yieldBox), _assetId, address(_sgl), type(uint200).max, uint48(block.timestamp));
        (Module[] memory modules, bytes[] memory calls) = marketHelper.repay(address(this), address(this), false, part);
        _sgl.execute(modules, calls, true);
    }

    function _setYieldBoxApproval(YieldBox yb, address target) internal {
        yb.setApprovalForAll(target, true);
    }

    function _setYieldBoxRevoke(YieldBox yb, address target) internal {
        yb.setApprovalForAll(target, false);
    }

    // -----------------------
    //
    // Approval helpers
    //
    // -----------------------
    function _createErc20Permit(address _owner, uint256 _pkSigner, address _spender, uint256 _amount, address _asset)
        internal
        returns (ERC20PermitStruct memory permitStruct, uint8 v_, bytes32 r_, bytes32 s_)
    {
        permitStruct = ERC20PermitStruct({owner: _owner, spender: _spender, value: _amount, nonce: 0, deadline: 1 days});
        bytes32 digest_ = ITOFT(_asset).getTypedDataHash(permitStruct);
        (v_, r_, s_) = vm.sign(_pkSigner, digest_);
    }

    struct Erc20PearlmitBatchPermitInternal {
        address _asset;
        uint256 _id;
        address _owner;
        uint256 _pkSigner;
        address _operator;
        uint256 _amount;
        uint256 _deadline;
    }

    function _createErc20PearlmitBatchPermit(Erc20PearlmitBatchPermitInternal memory data)
        internal
        returns (IPearlmit.PermitBatchTransferFrom memory batchData, bytes32 hashedData)
    {
        (IPearlmit.SignatureApproval[] memory signatureApprovals, bytes32[] memory hashApprovals) =
        _getPearlmitSigApprovals(
            data._asset, data._id, data._owner, data._pkSigner, data._operator, data._amount, data._deadline
        );

        bytes memory signedPermit;
        {
            bytes32 digest = ECDSA.toTypedDataHash(
                pearlmit.domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        PearlmitHash._PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                        keccak256(abi.encodePacked(hashApprovals)),
                        0, //nonce
                        data._deadline, //deadline
                        pearlmit.masterNonce(data._owner),
                        data._owner,
                        keccak256("0x")
                    )
                )
            );
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(data._pkSigner, digest);
            signedPermit = abi.encodePacked(r, s, v);
        }

        hashedData = keccak256("0x");
        batchData = IPearlmit.PermitBatchTransferFrom({
            approvals: signatureApprovals,
            owner: data._owner,
            nonce: 0,
            sigDeadline: uint48(data._deadline), //deadline
            signedPermit: signedPermit,
            masterNonce: pearlmit.masterNonce(data._owner),
            executor: data._owner,
            hashedData: hashedData
        });
    }

    function _getPearlmitSigApprovals(
        address _asset,
        uint256 _id,
        address _owner,
        uint256 _pkSigner,
        address _operator,
        uint256 _amount,
        uint256 _deadline
    ) private returns (IPearlmit.SignatureApproval[] memory, bytes32[] memory hashApprovals) {
        IPearlmit.SignatureApproval[] memory signatureApprovals = new IPearlmit.SignatureApproval[](1);

        signatureApprovals[0] = IPearlmit.SignatureApproval({
            tokenType: 20,
            token: _asset,
            id: _id,
            amount: uint200(_amount),
            operator: _operator
        });

        bytes32[] memory hashApprovals = new bytes32[](1);
        hashApprovals[0] = keccak256(
            abi.encode(
                PearlmitHash._PERMIT_SIGNATURE_APPROVAL_TYPEHASH,
                signatureApprovals[0].tokenType,
                signatureApprovals[0].token,
                signatureApprovals[0].id,
                signatureApprovals[0].amount,
                signatureApprovals[0].operator
            )
        );
    }
}
