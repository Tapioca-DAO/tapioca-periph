// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Lz
import {TestHelper} from "../../LZSetup/TestHelper.sol";


import {SimpleLeverageExecutor} from "tapioca-bar/markets/leverage/SimpleLeverageExecutor.sol";
import {ERC20WithoutStrategy} from "yieldbox/strategies/ERC20WithoutStrategy.sol";
import {SGLLiquidation} from "tapioca-bar/markets/singularity/SGLLiquidation.sol";
import {SGLCollateral} from "tapioca-bar/markets/singularity/SGLCollateral.sol";
import {SGLLeverage} from "tapioca-bar/markets/singularity/SGLLeverage.sol";
import {Singularity} from "tapioca-bar/markets/singularity/Singularity.sol";
import {SGLBorrow} from "tapioca-bar/markets/singularity/SGLBorrow.sol";
import {Cluster} from "tapioca-periph/Cluster/Cluster.sol";

import {BBLiquidation} from "tapioca-bar/markets/bigBang/BBLiquidation.sol";
import {BBCollateral} from "tapioca-bar/markets/bigBang/BBCollateral.sol";
import {BBLeverage} from "tapioca-bar/markets/bigBang/BBLeverage.sol";
import {BBBorrow} from "tapioca-bar/markets/bigBang/BBBorrow.sol";
import {BigBang} from "tapioca-bar/markets/bigBang/BigBang.sol";

import {MagnetarBaseModuleExternal} from "tapioca-periph/Magnetar/modules/MagnetarBaseModuleExternal.sol";
import {MagnetarAssetXChainModule} from "tapioca-periph/Magnetar/modules/MagnetarAssetXChainModule.sol";
import {MagnetarCollateralModule} from "tapioca-periph/Magnetar/modules/MagnetarCollateralModule.sol";
import {MagnetarMintXChainModule} from "tapioca-periph/Magnetar/modules/MagnetarMintXChainModule.sol";
import {ITapiocaOmnichainEngine} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarYieldBoxModule} from "tapioca-periph/Magnetar/modules/MagnetarYieldBoxModule.sol";
import {MagnetarOptionModule} from "tapioca-periph/Magnetar/modules/MagnetarOptionModule.sol";
import {MagnetarAssetModule} from "tapioca-periph/Magnetar/modules/MagnetarAssetModule.sol";
import {MagnetarMintModule} from "tapioca-periph/Magnetar/modules/MagnetarMintModule.sol";
import {MagnetarBaseModule} from "tapioca-periph/Magnetar/modules/MagnetarBaseModule.sol";
import {Magnetar} from "tapioca-periph/Magnetar/Magnetar.sol";

import {MagnetarHelper} from "tapioca-periph/Magnetar/MagnetarHelper.sol";
import {MarketHelper} from "tapioca-bar/markets/MarketHelper.sol";


import {UsdoMarketReceiverModule} from "tapioca-bar/usdo/modules/UsdoMarketReceiverModule.sol";
import {UsdoOptionReceiverModule} from "tapioca-bar/usdo/modules/UsdoOptionReceiverModule.sol";
import {UsdoReceiver} from "tapioca-bar/usdo/modules/UsdoReceiver.sol";
import {UsdoSender} from "tapioca-bar/usdo/modules/UsdoSender.sol";
import {Usdo, BaseUsdo} from "tapioca-bar/usdo/Usdo.sol";

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


import {ILeverageExecutor} from "tapioca-periph/interfaces/bar/ILeverageExecutor.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {IZeroXSwapper} from "tapioca-periph/interfaces/periph/IZeroXSwapper.sol";
import {IERC20} from "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import {ZerroXSwapperMockTarget} from "../../ZeroXSwapper/ZerroXSwapperMockTarget.sol";
import {ZeroXSwapper} from "tapioca-periph/Swapper/ZeroXSwapper.sol";

import {OracleMock} from "../../mocks/OracleMock.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {Cluster} from "tapioca-periph/Cluster/Cluster.sol";

import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {Pearlmit} from "tapioca-periph/pearlmit/Pearlmit.sol";

import {TokenType} from "yieldbox/enums/YieldBoxTokenType.sol";
import {IStrategy} from "yieldbox/interfaces/IStrategy.sol";
import {IYieldBox} from "yieldbox/interfaces/IYieldBox.sol";
import {YieldBox} from "yieldbox/YieldBox.sol";

import {IPenrose} from "tapioca-periph/interfaces/bar/IPenrose.sol";
import {Penrose} from "tapioca-bar/Penrose.sol";

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
    MagnetarAssetModule assetModule;
    MagnetarAssetXChainModule assetXChainModule;
    MagnetarCollateralModule collateralModule;
    MagnetarMintModule mintModule;
    MagnetarMintXChainModule mintXChainModule;
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

    uint32 aEid = 1;
    uint32 bEid = 2;

    ERC20Mock aERC20;
    ERC20Mock bERC20;

    Usdo asset;
    TOFT collateral;
    uint256 assetId;
    uint256 collateralId;

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
        aERC20 = new ERC20Mock();
        bERC20 = new ERC20Mock();

        clusterA = new Cluster(aEid, address(this));
        clusterB = new Cluster(bEid, address(this));
        pearlmit = new Pearlmit("Test", "1");

        Magnetar magnetarA = createMagnetar(address(clusterA), address(pearlmit));
        Magnetar magnetarB = createMagnetar(address(clusterB), address(pearlmit));

        magnetarHelper = new MagnetarHelper();
        marketHelper = new MarketHelper();
        oracle = new OracleMock("Test", "TT", 1 ether);

        magnetarA.setHelper(address(magnetarHelper));
        magnetarB.setHelper(address(magnetarHelper));

        clusterA.updateContract(0, address(magnetarA), true);
        clusterA.updateContract(0, address(magnetarHelper), true);
        clusterA.updateContract(0, address(oracle), true);
        clusterA.updateContract(0, address(pearlmit), true);
        clusterA.updateContract(0, address(asset), true);
        clusterA.updateContract(0, address(collateral), true);
        clusterA.updateContract(0, address(marketHelper), true);

        clusterB.updateContract(0, address(magnetarB), true);
        clusterB.updateContract(0, address(magnetarHelper), true);
        clusterB.updateContract(0, address(oracle), true);
        clusterB.updateContract(0, address(pearlmit), true);
        clusterB.updateContract(0, address(asset), true);
        clusterB.updateContract(0, address(collateral), true);
        clusterB.updateContract(0, address(marketHelper), true);

        vm.label(address(magnetarA), "Magnetar A");
        vm.label(address(magnetarA), "Magnetar B");
        vm.label(address(magnetarHelper), "MagnetarHelper");
        vm.label(address(oracle), "Oracle");
        vm.label(address(asset), "Usdo (asset)");
        vm.label(address(collateral), "Collateral (TOFT)");
        vm.label(address(aERC20), "aERC20");
        vm.label(address(bERC20), "bERC20");
        vm.label(address(marketHelper), "MarketHelper");
        vm.label(address(clusterA), "Cluster A");
        vm.label(address(clusterB), "Cluster B");

    }

    function setBBEthMarket(Penrose penrose, address market) external {
        penrose.setBigBangEthMarket(market);
    }


    function createMagnetar(address _cluster, address _pearlmit) public returns (Magnetar magnetar) {
        MagnetarSetupData memory setup;
        setup.assetModule = new MagnetarAssetModule();
        setup.assetXChainModule = new MagnetarAssetXChainModule();
        setup.collateralModule = new MagnetarCollateralModule();
        address _magnetarBaseModuleExternal = address(new MagnetarBaseModuleExternal());
        setup.mintModule = new MagnetarMintModule(_magnetarBaseModuleExternal);
        setup.mintXChainModule = new MagnetarMintXChainModule(_magnetarBaseModuleExternal);
        setup.optionModule = new MagnetarOptionModule(_magnetarBaseModuleExternal);
        setup.yieldBoxModule = new MagnetarYieldBoxModule();

        magnetar = new Magnetar(
            ICluster(_cluster),
            address(this),
            payable(setup.assetModule),
            payable(setup.assetXChainModule),
            payable(setup.collateralModule),
            payable(setup.mintModule),
            payable(setup.mintXChainModule),
            payable(setup.optionModule),
            payable(setup.yieldBoxModule),
            IPearlmit(_pearlmit)
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
    ) external returns (Penrose penrose, Singularity mediumRiskMC, BigBang bbMediumRiskMC) {
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

    function setAssetOracle(Penrose penrose, BigBang bb, address oracle) external {
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
            sgl.init(abi.encode(_modulesData, _tokensData, _data));
        }

        {
            Penrose(_sgl.penrose).addSingularity(_mc, address(sgl));
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
}