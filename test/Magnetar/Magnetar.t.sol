// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/StdCheats.sol";
import "forge-std/StdAssertions.sol";
import "forge-std/StdUtils.sol";
import {TestBase} from "forge-std/Base.sol";

import "forge-std/console.sol";

// External
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TapiocaOmnichainEngineHelper} from
    "tapioca-periph/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {TapiocaOmnichainEngineCodec} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainEngineCodec.sol";
import {MagnetarCollateralModule} from "tapioca-periph/Magnetar/modules/MagnetarCollateralModule.sol";
import {ITapiocaOmnichainEngine} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarYieldBoxModule} from "tapioca-periph/Magnetar/modules/MagnetarYieldBoxModule.sol";
import {MagnetarOptionModule} from "tapioca-periph/Magnetar/modules/MagnetarOptionModule.sol";
import {MagnetarMintModule} from "tapioca-periph/Magnetar/modules/MagnetarMintModule.sol";
import {MagnetarBaseModule} from "tapioca-periph/Magnetar/modules/MagnetarBaseModule.sol";
import {ILeverageExecutor} from "tapioca-periph/interfaces/bar/ILeverageExecutor.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {ERC20WithoutStrategy} from "yieldbox/strategies/ERC20WithoutStrategy.sol";
import {IZeroXSwapper} from "tapioca-periph/interfaces/periph/IZeroXSwapper.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {SendParamsMsg} from "tapioca-periph/interfaces/oft/ITOFT.sol";
import {IPenrose} from "tapioca-periph/interfaces/bar/IPenrose.sol";
import {Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {Pearlmit} from "tapioca-periph/pearlmit/Pearlmit.sol";
import {Magnetar} from "tapioca-periph/Magnetar/Magnetar.sol";
import {Cluster} from "tapioca-periph/Cluster/Cluster.sol";
import {Penrose} from "tapioca-bar/Penrose.sol";

import {TapiocaOptionsBrokerMock} from "../mocks/TapiocaOptionsBrokerMock.sol";
import {ERC1155Mock} from "../mocks/ERC1155Mock.sol";
import {TapOftMock} from "../mocks/TapOftMock.sol";

import {
    PrepareLzCallData,
    PrepareLzCallReturn,
    ComposeMsgData,
    LZSendParam,
    RemoteTransferMsg,
    TapiocaOmnichainEngineHelper
} from "tapioca-periph/tapiocaOmnichainEngine/extension/TapiocaOmnichainEngineHelper.sol";
import {
    MagnetarAction,
    MagnetarModule,
    MagnetarCall,
    DepositAddCollateralAndBorrowFromMarketData,
    MagnetarWithdrawData,
    DepositRepayAndRemoveCollateralFromMarketData,
    IMintData,
    IDepositData,
    IOptionsLockData,
    IOptionsParticipateData,
    ICommonExternalContracts,
    MintFromBBAndLendOnSGLData,
    IRemoveAndRepay,
    ExitPositionAndRemoveCollateralData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IOptionsUnlockData} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {MagnetarTestUtils, TestSingularityData, TestBigBangData} from "./MagnetarTestUtils.sol";
import {SimpleLeverageExecutor} from "tapioca-bar/markets/leverage/SimpleLeverageExecutor.sol";
import {IOptionsExitData} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {ISingularity, IMarket} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {SGLLiquidation} from "tapioca-bar/markets/singularity/SGLLiquidation.sol";
import {SGLCollateral} from "tapioca-bar/markets/singularity/SGLCollateral.sol";
import {SGLLeverage} from "tapioca-bar/markets/singularity/SGLLeverage.sol";
import {Singularity} from "tapioca-bar/markets/singularity/Singularity.sol";
import {MagnetarHelper} from "tapioca-periph/Magnetar/MagnetarHelper.sol";
import {SGLBorrow} from "tapioca-bar/markets/singularity/SGLBorrow.sol";
import {MarketHelper} from "tapioca-bar/markets/MarketHelper.sol";
import {Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {BigBang} from "tapioca-bar/markets/bigBang/BigBang.sol";

import {ZerroXSwapperMockTarget} from "../ZeroXSwapper/ZerroXSwapperMockTarget.sol";
import {ZeroXSwapper} from "tapioca-periph/Swapper/ZeroXSwapper.sol";

import {IWrappedNative} from "yieldbox/interfaces/IWrappedNative.sol";
import {YieldBoxURIBuilder} from "yieldbox/YieldBoxURIBuilder.sol";
import {IYieldBox} from "yieldbox/interfaces/IYieldBox.sol";
import {OracleMock} from "../mocks/OracleMock.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {YieldBox} from "yieldbox/YieldBox.sol";

// Lz
import {TestHelper} from "../LZSetup/TestHelper.sol";
import {
    SendParam,
    MessagingFee,
    MessagingReceipt,
    OFTReceipt
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";

contract MagnetarTest is TestBase, StdAssertions, StdCheats, StdUtils, TestHelper {
    Cluster cluster;
    Pearlmit pearlmit;
    Magnetar magnetar;
    MagnetarTestUtils utils;
    MagnetarHelper magnetarHelper;
    OracleMock oracle;
    MarketHelper marketHelper;

    uint32 aEid = 1;
    uint32 bEid = 2;

    ERC20Mock aERC20;
    ERC20Mock bERC20;
    ERC20Mock tapToken;

    ERC20Mock asset;
    ERC20Mock collateral;
    uint256 assetId;
    uint256 collateralId;
    uint256 tapTokenId;

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

    error Magnetar_UserMismatch();

    function setUp() public override {
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);
        vm.label(userA, "userA");
        vm.label(userB, "userB");
        setUpEndpoints(3, LibraryType.UltraLightNode);

        aERC20 = new ERC20Mock();
        bERC20 = new ERC20Mock();
        tapToken = new ERC20Mock();
        asset = new ERC20Mock();
        collateral = new ERC20Mock();

        cluster = new Cluster(aEid, address(this));
        pearlmit = new Pearlmit("Test", "1");
        
        TapiocaOmnichainEngineHelper toeHelper = new TapiocaOmnichainEngineHelper();
        MagnetarCollateralModule collateralModule = new MagnetarCollateralModule(IPearlmit(address(pearlmit)), address(toeHelper));
        MagnetarMintModule mintModule = new MagnetarMintModule(IPearlmit(address(pearlmit)), address(toeHelper));
        MagnetarOptionModule optionModule = new MagnetarOptionModule(IPearlmit(address(pearlmit)), address(toeHelper));
        MagnetarYieldBoxModule yieldBoxModule = new MagnetarYieldBoxModule(IPearlmit(address(pearlmit)), address(toeHelper));

        magnetar = new Magnetar(
            ICluster(address(cluster)),
            address(this),
            payable(collateralModule),
            payable(mintModule),
            payable(optionModule),
            payable(yieldBoxModule),
            IPearlmit(address(pearlmit)), 
            address(toeHelper)
        );

        utils = new MagnetarTestUtils();
        magnetarHelper = new MagnetarHelper();
        oracle = new OracleMock("Test", "TT", 1 ether);
        marketHelper = new MarketHelper();

        cluster.updateContract(0, address(magnetar), true);
        cluster.updateContract(0, address(magnetarHelper), true);
        cluster.updateContract(0, address(oracle), true);
        cluster.updateContract(0, address(pearlmit), true);
        cluster.updateContract(0, address(asset), true);
        cluster.updateContract(0, address(collateral), true);
        cluster.updateContract(0, address(marketHelper), true);

        vm.label(address(magnetar), "Magnetar");
        vm.label(address(magnetarHelper), "MagnetarHelper");
        vm.label(address(oracle), "Oracle");
        vm.label(address(asset), "Asset");
        vm.label(address(collateral), "Collateral");
        vm.label(address(aERC20), "aERC20");
        vm.label(address(bERC20), "bERC20");
        vm.label(address(marketHelper), "MarketHelper");

        asset.approve(address(pearlmit), type(uint256).max);
        collateral.approve(address(pearlmit), type(uint256).max);
        asset.approve(address(magnetar), type(uint256).max);
        collateral.approve(address(magnetar), type(uint256).max);

        magnetar.setHelper(address(magnetarHelper));
    }

    function _setupSgl(address _oracle) private returns (Singularity, Penrose, YieldBox) {
        // ZerroXSwapperMockTarget swapperTarget = new ZerroXSwapperMockTarget();
        // ZeroXSwapper swapper = new ZeroXSwapper(address(swapperTarget), address(0), ICluster(address(cluster)), address(this));
        // SimpleLeverageExecutor leverageExecutor = new SimpleLeverageExecutor(IZeroXSwapper(address(swapper)), ICluster(address(cluster)));

        YieldBoxURIBuilder ybUri = new YieldBoxURIBuilder();
        YieldBox yb = new YieldBox(IWrappedNative(address(aERC20)), ybUri);

        Penrose penrose;
        Singularity mc;
        {
            ERC20WithoutStrategy aERC20Strategy = utils.createYieldBoxEmptyStrategy(address(yb), address(aERC20));
            uint256 aERC20Id = utils.registerYieldBoxAsset(address(yb), address(aERC20), address(aERC20Strategy));

            (penrose, mc,) = utils.createPenrose(
                address(pearlmit),
                IYieldBox(address(yb)),
                ICluster(address(cluster)),
                address(aERC20),
                address(aERC20),
                aERC20Id,
                aERC20Id
            );
        }

        Singularity sgl;
        {
            ERC20WithoutStrategy collateralStrategy =
                utils.createYieldBoxEmptyStrategy(address(yb), address(collateral));
            collateralId = utils.registerYieldBoxAsset(address(yb), address(collateral), address(collateralStrategy));

            ERC20WithoutStrategy assetStrategy = utils.createYieldBoxEmptyStrategy(address(yb), address(asset));
            assetId = utils.registerYieldBoxAsset(address(yb), address(asset), address(assetStrategy));

            sgl = utils.createSingularity(
                TestSingularityData(
                    address(penrose),
                    address(asset),
                    assetId,
                    address(collateral),
                    collateralId,
                    ITapiocaOracle(_oracle),
                    ILeverageExecutor(address(0))
                ),
                address(mc)
            );
        }

        return (sgl, penrose, yb);
    }

    function _setupBb(address _oracle) private returns (BigBang, Penrose, YieldBox) {
        YieldBoxURIBuilder ybUri = new YieldBoxURIBuilder();
        YieldBox yb = new YieldBox(IWrappedNative(address(aERC20)), ybUri);

        ERC20WithoutStrategy collateralStrategy = utils.createYieldBoxEmptyStrategy(address(yb), address(collateral));
        collateralId = utils.registerYieldBoxAsset(address(yb), address(collateral), address(collateralStrategy));

        ERC20WithoutStrategy aERC20Strategy = utils.createYieldBoxEmptyStrategy(address(yb), address(aERC20));
        uint256 aERC20Id = utils.registerYieldBoxAsset(address(yb), address(aERC20), address(aERC20Strategy));

        (Penrose penrose,, BigBang bbMediumRiskMC) = utils.createPenrose(
            address(pearlmit),
            IYieldBox(address(yb)),
            ICluster(address(cluster)),
            address(aERC20),
            address(aERC20),
            aERC20Id,
            aERC20Id
        );

        {
            ERC20WithoutStrategy assetStrategy = utils.createYieldBoxEmptyStrategy(address(yb), address(asset));
            uint256 assetId = utils.registerYieldBoxAsset(address(yb), address(asset), address(assetStrategy));

            vm.prank(address(utils));
            penrose.setUsdoToken(address(asset), assetId);
        }

        BigBang bb = utils.createBigBang(
            TestBigBangData(
                address(penrose),
                address(collateral),
                collateralId,
                ITapiocaOracle(_oracle),
                ILeverageExecutor(address(0)),
                0,
                0,
                0
            ),
            address(bbMediumRiskMC)
        );

        utils.setAssetOracle(penrose, bb, _oracle);

        return (bb, penrose, yb);
    }

    function test_receive_erc1155() public {
        ERC1155Mock erc1155 = new ERC1155Mock();
        erc1155.mint(address(magnetar), 1, 1);
        assertEq(erc1155.balanceOf(address(magnetar), 1), 1);
    }

    function test_get_sgl_info() public {
        (Singularity sgl,,) = _setupSgl(address(oracle));

        ISingularity[] memory arr = new ISingularity[](1);
        arr[0] = ISingularity(address(sgl));

        MagnetarHelper.SingularityInfo[] memory response = magnetarHelper.singularityMarketInfo(address(this), arr);

        assertEq(response[0].market.totalCollateralShare, 0);
        assertEq(response[0].market.userCollateralShare, 0);
        assertEq(response[0].market.collateralizationRate, 75_000);
    }

    function test_yieldBox_deposit() public {
        (Singularity sgl,, YieldBox yieldBox) = _setupSgl(address(oracle));
        cluster.updateContract(0, address(sgl), true);
        cluster.updateContract(0, address(yieldBox), true);
        vm.label(address(sgl), "Singularity");
        vm.label(address(yieldBox), "YieldBox");

        uint256 tokenAmount_ = 1 ether;
        {
            deal(address(asset), address(this), tokenAmount_);
        }

        {
            asset.approve(address(yieldBox), type(uint256).max);
            yieldBox.setApprovalForAll(address(magnetar), true);
        }

        {
            uint256 assetShare = yieldBox.toShare(assetId, tokenAmount_, false);
            bytes memory depositToYbData = abi.encodeWithSelector(
                MagnetarYieldBoxModule.depositAsset.selector,
                address(yieldBox),
                assetId,
                address(this),
                address(this),
                0,
                assetShare
            );
            MagnetarCall[] memory calls = new MagnetarCall[](1);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: depositToYbData
            });
            magnetar.burst(calls);

            assertGt(yieldBox.balanceOf(address(this), assetId), 0);
        }
    }

    function test_lend() public {
        (Singularity sgl,, YieldBox yieldBox) = _setupSgl(address(oracle));
        cluster.updateContract(0, address(sgl), true);
        cluster.updateContract(0, address(yieldBox), true);
        vm.label(address(sgl), "Singularity");
        vm.label(address(yieldBox), "YieldBox");

        uint256 tokenAmount_ = 1 ether;
        {
            deal(address(asset), address(this), tokenAmount_);
        }

        {
            // deposit to YB approvals
            asset.approve(address(yieldBox), type(uint256).max);
            yieldBox.setApprovalForAll(address(magnetar), true);

            // lend approvals
            pearlmit.approve(address(yieldBox), assetId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
            yieldBox.setApprovalForAll(address(pearlmit), true);
            sgl.approve(address(magnetar), type(uint256).max);
        }

        {
            uint256 assetShare = yieldBox.toShare(assetId, tokenAmount_, false);
            bytes memory depositToYbData = abi.encodeWithSelector(
                MagnetarYieldBoxModule.depositAsset.selector,
                address(yieldBox),
                assetId,
                address(this),
                address(this),
                0,
                assetShare
            );
            bytes memory lendData =
                abi.encodeWithSelector(Singularity.addAsset.selector, address(this), address(this), false, assetShare);

            MagnetarCall[] memory calls = new MagnetarCall[](2);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: depositToYbData
            });
            calls[1] = MagnetarCall({id: uint8(MagnetarAction.Market), target: address(sgl), value: 0, call: lendData});

            magnetar.burst(calls);

            assertEq(yieldBox.balanceOf(address(this), assetId), 0);
            assertGt(sgl.balanceOf(address(this)), 0);
        }
    }

    function test_repay() public {
        (Singularity sgl,, YieldBox yieldBox) = _setupSgl(address(oracle));
        cluster.updateContract(0, address(sgl), true);
        cluster.updateContract(0, address(yieldBox), true);
        vm.label(address(sgl), "Singularity");
        vm.label(address(yieldBox), "YieldBox");

        uint256 tokenAmount_ = 1 ether;
        uint256 borrowAmount_ = 1e17;
        uint256 repayDepositAmount_ = 1 ether;
        uint256 repayAmount_ = 1e17;

        {
            deal(address(asset), address(this), tokenAmount_);
            deal(address(collateral), address(this), tokenAmount_);
        }

        {
            // deposit to YB approvals
            asset.approve(address(yieldBox), type(uint256).max);
            yieldBox.setApprovalForAll(address(magnetar), true);
            yieldBox.setApprovalForAll(address(pearlmit), true);

            // lend approvals
            pearlmit.approve(address(yieldBox), assetId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
            sgl.approve(address(magnetar), type(uint256).max);  

            // collateral approvals
            pearlmit.approve(
                address(yieldBox), collateralId, address(sgl), type(uint200).max, uint48(block.timestamp)
            ); // Atomic approval
            sgl.approve(address(magnetar), type(uint256).max);

            // market operations approvals
            pearlmit.approve(address(asset), 0, address(magnetar), type(uint200).max, uint48(block.timestamp)); // Atomic approval
            pearlmit.approve(address(collateral), 0, address(magnetar), type(uint200).max, uint48(block.timestamp)); // Atomic approval
            sgl.approve(address(magnetar), type(uint256).max);
            sgl.approveBorrow(address(magnetar), type(uint256).max);
        }
        {
            uint256 assetShare = yieldBox.toShare(assetId, tokenAmount_, false);
            bytes memory depositToYbData = abi.encodeWithSelector(
                MagnetarYieldBoxModule.depositAsset.selector,
                address(yieldBox),
                assetId,
                address(this),
                address(this),
                tokenAmount_,
                0
            );
            bytes memory lendData =
                abi.encodeWithSelector(Singularity.addAsset.selector, address(this), address(this), false, assetShare);

            MagnetarCall[] memory calls = new MagnetarCall[](2);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: depositToYbData
            });
            calls[1] = MagnetarCall({id: uint8(MagnetarAction.Market), target: address(sgl), value: 0, call: lendData});

            magnetar.burst(calls);

            assertEq(yieldBox.balanceOf(address(this), assetId), 0);
            assertGt(sgl.balanceOf(address(this)), 0);
        }
        //add collateral
        {
            bytes memory depositAddCollateralAndBorrowFromMarketData = abi.encodeWithSelector(
                MagnetarCollateralModule.depositAddCollateralAndBorrowFromMarket.selector,
                DepositAddCollateralAndBorrowFromMarketData({
                    market: address(sgl),
                    marketHelper: address(marketHelper),
                    user: address(this),
                    collateralAmount: tokenAmount_,
                    borrowAmount: borrowAmount_,
                    deposit: true,
                    withdrawParams: MagnetarWithdrawData({
                        yieldBox: address(yieldBox),
                        assetId: 0,
                        receiver: address(this),
                        amount: 0,
                        withdraw: false,
                        unwrap: false
                    })
                })
            );
            MagnetarCall[] memory calls = new MagnetarCall[](1);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.CollateralModule),
                target: address(yieldBox),
                value: 0,
                call: depositAddCollateralAndBorrowFromMarketData
            });

            magnetar.burst(calls);
        }

        // check collateral
        {
            uint256 colShare = sgl._userCollateralShare(address(this));
            uint256 colAmount = yieldBox.toAmount(collateralId, colShare, false);
            assertEq(colAmount, tokenAmount_);
        }

        uint256 userBorrowPartBefore = sgl._userBorrowPart(address(this));
        deal(address(asset), address(this), repayDepositAmount_);
        // repay
        {
            bytes memory repayData = abi.encodeWithSelector(
                MagnetarCollateralModule.depositRepayAndRemoveCollateralFromMarket.selector,
                DepositRepayAndRemoveCollateralFromMarketData({
                    market: address(sgl),
                    marketHelper: address(marketHelper),
                    user: address(this),
                    depositAmount: repayDepositAmount_,
                    repayAmount: repayAmount_,
                    collateralAmount: 0,
                    withdrawCollateralParams: MagnetarWithdrawData({
                        yieldBox: address(yieldBox),
                        assetId: 0,
                        receiver: address(this),
                        amount: 0,
                        withdraw: false,
                        unwrap: false
                    })
                })
            );

            MagnetarCall[] memory calls = new MagnetarCall[](1);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.CollateralModule),
                target: address(yieldBox),
                value: 0,
                call: repayData
            });

            pearlmit.approve(address(yieldBox), assetId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
            sgl.approve(address(magnetar), type(uint256).max);  


            magnetar.burst(calls);
        }

        // check repayment
        {
            uint256 userBorrowPart = sgl._userBorrowPart(address(this));
            assertLt(userBorrowPart, userBorrowPartBefore);
        }
    }

    function test_withdraw_sanitization() public {
        (Singularity sgl,, YieldBox yieldBox) = _setupSgl(address(oracle));

        cluster.updateContract(0, address(sgl), true);
        cluster.updateContract(0, address(yieldBox), true);
        vm.label(address(sgl), "Singularity");
        vm.label(address(yieldBox), "YieldBox");

        uint256 tokenAmount_ = 1 ether;
        uint256 borrowAmount_ = 1e17;

        pearlmit.approve(address(asset), 0, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        pearlmit.approve(address(collateral), 0, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval

        pearlmit.approve(address(asset), 0, address(magnetar), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        pearlmit.approve(address(collateral), 0, address(magnetar), type(uint200).max, uint48(block.timestamp)); // Atomic approval

        pearlmit.approve(address(yieldBox), assetId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        pearlmit.approve(address(yieldBox), collateralId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval

        yieldBox.setApprovalForAll(address(pearlmit), true);

        //approvals
        {
            asset.approve(address(sgl), type(uint256).max);
            collateral.approve(address(sgl), type(uint256).max);
            asset.approve(address(yieldBox), type(uint256).max);
            collateral.approve(address(yieldBox), type(uint256).max);
            yieldBox.setApprovalForAll(address(magnetar), true);
            yieldBox.setApprovalForAll(address(sgl), true);
            sgl.approve(address(magnetar), type(uint256).max);
            sgl.approveBorrow(address(magnetar), type(uint256).max);
        }

        //deal
        {
            deal(address(asset), address(this), tokenAmount_);
            deal(address(collateral), address(this), tokenAmount_);
        }

        {
            uint256 assetShare = yieldBox.toShare(assetId, tokenAmount_, false);
            bytes memory depositToYbData = abi.encodeWithSelector(
                MagnetarYieldBoxModule.depositAsset.selector,
                address(yieldBox),
                assetId,
                address(this),
                address(this),
                0,
                assetShare
            );
            bytes memory lendData =
                abi.encodeWithSelector(Singularity.addAsset.selector, address(this), address(this), false, assetShare);

            MagnetarCall[] memory calls = new MagnetarCall[](2);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: depositToYbData
            });
            calls[1] = MagnetarCall({id: uint8(MagnetarAction.Market), target: address(sgl), value: 0, call: lendData});

            magnetar.burst(calls);

            assertEq(yieldBox.balanceOf(address(this), assetId), 0);
            assertGt(sgl.balanceOf(address(this)), 0);
        }

        //add collateral
        {
            bytes memory depositAddCollateralAndBorrowFromMarketData = abi.encodeWithSelector(
                MagnetarCollateralModule.depositAddCollateralAndBorrowFromMarket.selector,
                DepositAddCollateralAndBorrowFromMarketData({
                    market: address(sgl),
                    marketHelper: address(marketHelper),
                    user: address(this),
                    collateralAmount: tokenAmount_,
                    borrowAmount: borrowAmount_,
                    deposit: true,
                    withdrawParams: MagnetarWithdrawData({
                        yieldBox: address(yieldBox),
                        assetId: 0,
                        receiver: address(this),
                        amount: 0,
                        withdraw: false,
                        unwrap: false
                    })
                })
            );
            MagnetarCall[] memory calls = new MagnetarCall[](1);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.CollateralModule),
                target: address(yieldBox),
                value: 0,
                call: depositAddCollateralAndBorrowFromMarketData
            });

            magnetar.burst(calls);
        }

        {
            uint256 colShare = sgl._userCollateralShare(address(this));
            uint256 colAmount = yieldBox.toAmount(collateralId, colShare, false);
            assertEq(colAmount, tokenAmount_);
        }

        {
            (Module[] memory borrowCallModules, bytes[] memory borrowCalls) =
                marketHelper.borrow(address(this), address(this), borrowAmount_);
            sgl.execute(borrowCallModules, borrowCalls, true);

            uint256 borrowPart = sgl._userBorrowPart(address(this));
            assertGt(borrowPart, 0);

            yieldBox.transfer(address(this), address(magnetar), assetId, yieldBox.balanceOf(address(this), assetId));
        }

        {
            MagnetarWithdrawData memory withdrawData = MagnetarWithdrawData({
                yieldBox: address(yieldBox),
                assetId: assetId,
                receiver: address(this),
                amount: borrowAmount_,
                withdraw: true,
                unwrap: true
            });
            MagnetarCall[] memory calls = new MagnetarCall[](1);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: abi.encodeWithSelector(MagnetarYieldBoxModule.withdrawHere.selector, withdrawData)
            });

            vm.expectRevert(); //fails with Magnetar_UserMismatch
            magnetar.burst(calls);
        }
    }

    function test_withdraw() public {
        (Singularity sgl,, YieldBox yieldBox) = _setupSgl(address(oracle));

        cluster.updateContract(0, address(sgl), true);
        cluster.updateContract(0, address(yieldBox), true);
        vm.label(address(sgl), "Singularity");
        vm.label(address(yieldBox), "YieldBox");

        uint256 tokenAmount_ = 1 ether;
        uint256 borrowAmount_ = 1e17;

        pearlmit.approve(address(asset), 0, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        pearlmit.approve(address(collateral), 0, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval

        pearlmit.approve(address(asset), 0, address(magnetar), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        pearlmit.approve(address(collateral), 0, address(magnetar), type(uint200).max, uint48(block.timestamp)); // Atomic approval

        pearlmit.approve(address(yieldBox), assetId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        pearlmit.approve(address(yieldBox), collateralId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval

        yieldBox.setApprovalForAll(address(pearlmit), true);

        //approvals
        {
            asset.approve(address(sgl), type(uint256).max);
            collateral.approve(address(sgl), type(uint256).max);
            asset.approve(address(yieldBox), type(uint256).max);
            collateral.approve(address(yieldBox), type(uint256).max);
            yieldBox.setApprovalForAll(address(magnetar), true);
            yieldBox.setApprovalForAll(address(sgl), true);
            sgl.approve(address(magnetar), type(uint256).max);
            sgl.approveBorrow(address(magnetar), type(uint256).max);
        }

        //deal
        {
            deal(address(asset), address(this), tokenAmount_);
            deal(address(collateral), address(this), tokenAmount_);
        }

        {
            uint256 assetShare = yieldBox.toShare(assetId, tokenAmount_, false);
            bytes memory depositToYbData = abi.encodeWithSelector(
                MagnetarYieldBoxModule.depositAsset.selector,
                address(yieldBox),
                assetId,
                address(this),
                address(this),
                0,
                assetShare
            );
            bytes memory lendData =
                abi.encodeWithSelector(Singularity.addAsset.selector, address(this), address(this), false, assetShare);

            MagnetarCall[] memory calls = new MagnetarCall[](2);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: depositToYbData
            });
            calls[1] = MagnetarCall({id: uint8(MagnetarAction.Market), target: address(sgl), value: 0, call: lendData});

            magnetar.burst(calls);

            assertEq(yieldBox.balanceOf(address(this), assetId), 0);
            assertGt(sgl.balanceOf(address(this)), 0);
        }

        //add collateral
        {
            bytes memory depositAddCollateralAndBorrowFromMarketData = abi.encodeWithSelector(
                MagnetarCollateralModule.depositAddCollateralAndBorrowFromMarket.selector,
                DepositAddCollateralAndBorrowFromMarketData({
                    market: address(sgl),
                    marketHelper: address(marketHelper),
                    user: address(this),
                    collateralAmount: tokenAmount_,
                    borrowAmount: borrowAmount_,
                    deposit: true,
                    withdrawParams: MagnetarWithdrawData({
                        yieldBox: address(yieldBox),
                        assetId: 0,
                        receiver: address(this),
                        amount: 0,
                        withdraw: false,
                        unwrap: false
                    })
                })
            );
            MagnetarCall[] memory calls = new MagnetarCall[](1);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.CollateralModule),
                target: address(yieldBox),
                value: 0,
                call: depositAddCollateralAndBorrowFromMarketData
            });

            magnetar.burst(calls);
        }

        {
            uint256 colShare = sgl._userCollateralShare(address(this));
            uint256 colAmount = yieldBox.toAmount(collateralId, colShare, false);
            assertEq(colAmount, tokenAmount_);
        }

        {
            (Module[] memory borrowCallModules, bytes[] memory borrowCalls) =
                marketHelper.borrow(address(this), address(this), borrowAmount_);
            sgl.execute(borrowCallModules, borrowCalls, true);

            uint256 borrowPart = sgl._userBorrowPart(address(this));
            assertGt(borrowPart, 0);

            yieldBox.transfer(address(this), address(magnetar), assetId, yieldBox.balanceOf(address(this), assetId));
        }

        {
            MagnetarWithdrawData memory withdrawData = MagnetarWithdrawData({
                yieldBox: address(yieldBox),
                assetId: assetId,
                receiver: address(this),
                amount: borrowAmount_,
                withdraw: true,
                unwrap: false
            });
            MagnetarCall[] memory calls = new MagnetarCall[](1);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: abi.encodeWithSelector(MagnetarYieldBoxModule.withdrawHere.selector, withdrawData)
            });

            magnetar.burst(calls);

            uint256 balanceOf = asset.balanceOf(address(this));
            assertGt(balanceOf, 0);
            assertEq(balanceOf, borrowAmount_);
        }
    }

    function test_magnetar_execute_decode() public {
        (BigBang bb, Penrose penrose, YieldBox yieldBox) = _setupBb(address(oracle));
        utils.setBBEthMarket(penrose, address(bb));

        cluster.updateContract(0, address(bb), true);
        cluster.updateContract(0, address(yieldBox), true);
        vm.label(address(bb), "BigBang");
        vm.label(address(yieldBox), "YieldBox");

        uint256 tokenAmount_ = 1 ether;

        //deal
        {
            deal(address(collateral), address(this), tokenAmount_);
        }

        {
            MagnetarCall[] memory magnetarCalls = new MagnetarCall[](2);

            pearlmit.approve(
                address(yieldBox), collateralId, address(bb), type(uint200).max, uint48(block.timestamp)
            ); // Atomic approval
            pearlmit.approve(
                address(yieldBox), collateralId, address(magnetar), type(uint200).max, uint48(block.timestamp)
            ); // Atomic approval
            collateral.approve(address(magnetar), type(uint256).max);
            yieldBox.setApprovalForAll(address(pearlmit), true);

            //deposit approvals
            yieldBox.setApprovalForAll(address(magnetar), true);
            collateral.approve(address(yieldBox), type(uint256).max); //for yb deposit

            uint256 collateralShare = yieldBox.toShare(collateralId, tokenAmount_, false);
            bytes memory depositToYbData = abi.encodeWithSelector(
                MagnetarYieldBoxModule.depositAsset.selector,
                address(yieldBox),
                collateralId,
                address(this),
                address(this),
                0,
                collateralShare
            );
            magnetarCalls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: depositToYbData
            });

            Module[] memory modules;
            bytes[] memory calls;
            (modules, calls) = marketHelper.addCollateral(address(this), address(this), false, tokenAmount_, 0);
            bytes memory data = abi.encodeWithSelector(Singularity.execute.selector, modules, calls, true);

            magnetarCalls[1] =
                MagnetarCall({id: uint8(MagnetarAction.Market), target: address(bb), value: 0, call: data});

            magnetar.burst(magnetarCalls);
        }
    }

    function test_mint() public {
        (BigBang bb, Penrose penrose, YieldBox yieldBox) = _setupBb(address(oracle));
        utils.setBBEthMarket(penrose, address(bb));

        cluster.updateContract(0, address(bb), true);
        cluster.updateContract(0, address(yieldBox), true);
        vm.label(address(bb), "BigBang");
        vm.label(address(yieldBox), "YieldBox");

        uint256 tokenAmount_ = 1 ether;
        uint256 mintAmount_ = 1e17;

        pearlmit.approve(address(collateral), 0, address(magnetar), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        pearlmit.approve(address(yieldBox), collateralId, address(bb), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        yieldBox.setApprovalForAll(address(magnetar), true);
        yieldBox.setApprovalForAll(address(pearlmit), true);
        bb.approveBorrow(address(magnetar), type(uint256).max);

        //deal
        {
            deal(address(collateral), address(this), tokenAmount_);
        }

        {
            bytes memory mintData = abi.encodeWithSelector(
                MagnetarMintModule.mintBBLendSGLLockTOLP.selector,
                MintFromBBAndLendOnSGLData({
                    user: address(this),
                    lendAmount: 0,
                    mintData: IMintData({
                        mint: true,
                        mintAmount: mintAmount_,
                        collateralDepositData: IDepositData({deposit: true, amount: tokenAmount_})
                    }),
                    depositData: IDepositData({deposit: false, amount: 0}),
                    lockData: IOptionsLockData({lock: false, amount: 0, lockDuration: 0, target: address(0), fraction: 0}),
                    participateData: IOptionsParticipateData({participate: false, target: address(0), tOLPTokenId: 0}),
                    externalContracts: ICommonExternalContracts({
                        singularity: address(0),
                        magnetar: address(magnetar),
                        bigBang: address(bb),
                        marketHelper: address(marketHelper)
                    })
                })
            );

            MagnetarCall[] memory calls = new MagnetarCall[](1);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.MintModule),
                target: address(yieldBox), //this is ignored
                value: 0,
                call: mintData
            });

            magnetar.burst(calls);
        }

        // checks
        {
            uint256 colShare = bb._userCollateralShare(address(this));
            assertGt(colShare, 0);
        }
    }

    function test_exit_and_remove_collateral() public {
        (BigBang bb, Penrose penrose, YieldBox yieldBox) = _setupBb(address(oracle));
        bb.approve(address(magnetar), type(uint256).max);
        utils.setBBEthMarket(penrose, address(bb));

        cluster.updateContract(0, address(bb), true);
        cluster.updateContract(0, address(yieldBox), true);
        vm.label(address(bb), "BigBang");
        vm.label(address(yieldBox), "YieldBox");

        uint256 tokenAmount_ = 1 ether;
        uint256 mintAmount_ = 1e17;

        pearlmit.approve(address(collateral), 0, address(magnetar), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        pearlmit.approve(address(yieldBox), collateralId, address(bb), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        yieldBox.setApprovalForAll(address(magnetar), true);
        yieldBox.setApprovalForAll(address(pearlmit), true);
        bb.approveBorrow(address(magnetar), type(uint256).max);

        //deal
        {
            deal(address(collateral), address(this), tokenAmount_);
        }

        //mint
        {
            bytes memory mintData = abi.encodeWithSelector(
                MagnetarMintModule.mintBBLendSGLLockTOLP.selector,
                MintFromBBAndLendOnSGLData({
                    user: address(this),
                    lendAmount: 0,
                    mintData: IMintData({
                        mint: true,
                        mintAmount: mintAmount_,
                        collateralDepositData: IDepositData({deposit: true, amount: tokenAmount_})
                    }),
                    depositData: IDepositData({deposit: false, amount: 0}),
                    lockData: IOptionsLockData({lock: false, amount: 0, lockDuration: 0, target: address(0), fraction: 0}),
                    participateData: IOptionsParticipateData({participate: false, target: address(0), tOLPTokenId: 0}),
                    externalContracts: ICommonExternalContracts({
                        singularity: address(0),
                        magnetar: address(magnetar),
                        bigBang: address(bb),
                        marketHelper: address(marketHelper)
                    })
                })
            );

            MagnetarCall[] memory calls = new MagnetarCall[](1);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.MintModule),
                target: address(yieldBox), //this is ignored
                value: 0,
                call: mintData
            });

            magnetar.burst(calls);
        }

        uint256 colShare = bb._userCollateralShare(address(this));
        assertGt(colShare, 0);

        uint256 repayAmount_ = bb._userBorrowPart(address(this));
        // exit and remove
        {
            IERC20(bb._asset()).approve(address(yieldBox), type(uint256).max); //for yb deposit
            yieldBox.setApprovalForAll(address(bb), true); //for repay

            deal(address(asset), address(this), repayAmount_); //deal more asset to be able to fully repay
            uint256 assetShare = yieldBox.toShare(bb._assetId(), repayAmount_, false);

            bytes memory depositToYbData = abi.encodeWithSelector(
                MagnetarYieldBoxModule.depositAsset.selector,
                address(yieldBox),
                bb._assetId(),
                address(this),
                address(this),
                0,
                assetShare
            );

            bytes memory removeData = abi.encodeWithSelector(
                MagnetarOptionModule.exitPositionAndRemoveCollateral.selector,
                ExitPositionAndRemoveCollateralData({
                    user: address(this),
                    externalData: ICommonExternalContracts({
                        magnetar: address(magnetar),
                        singularity: address(0),
                        bigBang: address(bb),
                        marketHelper: address(marketHelper)
                    }),
                    removeAndRepayData: IRemoveAndRepay({
                        removeAssetFromSGL: false,
                        removeAmount: 0,
                        repayAssetOnBB: true,
                        repayAmount: repayAmount_,
                        removeCollateralFromBB: true,
                        collateralAmount: tokenAmount_ / 2,
                        exitData: IOptionsExitData({exit: false, target: address(0), oTAPTokenID: 0}),
                        unlockData: IOptionsUnlockData({unlock: false, target: address(0), tokenId: 0}),
                        assetWithdrawData: MagnetarWithdrawData({
                            yieldBox: address(yieldBox),
                            assetId: 0,
                            receiver: address(this),
                            amount: 0,
                            withdraw: false,
                            unwrap: false
                        }),
                        collateralWithdrawData: MagnetarWithdrawData({
                            yieldBox: address(yieldBox),
                            assetId: 0,
                            receiver: address(this),
                            amount: 0,
                            withdraw: false,
                            unwrap: false
                        })
                    })
                })
            );

            MagnetarCall[] memory calls = new MagnetarCall[](2);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: depositToYbData
            });
            calls[1] = MagnetarCall({
                id: uint8(MagnetarAction.OptionModule),
                target: address(yieldBox), //this is ignored
                value: 0,
                call: removeData
            });

            magnetar.burst(calls);
        }
    }

    function test_sgl_lend() public {
        (Singularity sgl,, YieldBox yieldBox) = _setupSgl(address(oracle));

        cluster.updateContract(0, address(sgl), true);
        cluster.updateContract(0, address(yieldBox), true);
        vm.label(address(sgl), "Singularity");
        vm.label(address(yieldBox), "YieldBox");

        uint256 tokenAmount_ = 1 ether;

        // lend approvals
        sgl.approve(address(magnetar), type(uint256).max);
        pearlmit.approve(address(yieldBox), assetId, address(sgl), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        yieldBox.setApprovalForAll(address(pearlmit), true);

        //yb deposit approvals
        yieldBox.setApprovalForAll(address(magnetar), true);
        asset.approve(address(yieldBox), type(uint256).max); //for yb deposit

        //deal
        {
            deal(address(asset), address(this), tokenAmount_);
        }

        {
            uint256 assetShare = yieldBox.toShare(assetId, tokenAmount_, false);
            bytes memory depositToYbData = abi.encodeWithSelector(
                MagnetarYieldBoxModule.depositAsset.selector,
                address(yieldBox),
                assetId,
                address(this),
                address(this),
                0,
                assetShare
            );

            bytes memory mintData = abi.encodeWithSelector(
                MagnetarMintModule.mintBBLendSGLLockTOLP.selector,
                MintFromBBAndLendOnSGLData({
                    user: address(this),
                    lendAmount: tokenAmount_,
                    mintData: IMintData({
                        mint: false,
                        mintAmount: 0,
                        collateralDepositData: IDepositData({deposit: false, amount: 0})
                    }),
                    depositData: IDepositData({deposit: false, amount: 0}),
                    lockData: IOptionsLockData({lock: false, amount: 0, lockDuration: 0, target: address(0), fraction: 0}),
                    participateData: IOptionsParticipateData({participate: false, target: address(0), tOLPTokenId: 0}),
                    externalContracts: ICommonExternalContracts({
                        singularity: address(sgl),
                        magnetar: address(magnetar),
                        bigBang: address(0),
                        marketHelper: address(marketHelper)
                    })
                })
            );

            MagnetarCall[] memory calls = new MagnetarCall[](2);
            calls[0] = MagnetarCall({
                id: uint8(MagnetarAction.YieldBoxModule),
                target: address(yieldBox),
                value: 0,
                call: depositToYbData
            });
            calls[1] = MagnetarCall({
                id: uint8(MagnetarAction.MintModule),
                target: address(yieldBox), //this is ignored
                value: 0,
                call: mintData
            });

            magnetar.burst(calls);
        }

        // checks
        {
            uint256 lentAmount = sgl.balanceOf(address(this));
            assertGt(lentAmount, 0);
        }
    }

    function test_exercise_option() public {
        TapOftMock tapOft = new TapOftMock();
        TapOftMock oTAP = new TapOftMock();
        ERC20Mock paymentToken = new ERC20Mock();
        TapiocaOptionsBrokerMock tOb = new TapiocaOptionsBrokerMock(address(oTAP), address(tapOft), IPearlmit(address(pearlmit)));


        cluster.updateContract(0, address(tOb), true);
        cluster.updateContract(0, address(tapOft), true);
        cluster.updateContract(0, address(paymentToken), true);

        deal(address(paymentToken), address(this), 1 ether);

        pearlmit.approve(address(paymentToken), 0, address(magnetar), uint200(1 ether), uint48(block.timestamp));
        paymentToken.approve(address(pearlmit), 1 ether);

        MagnetarCall[] memory calls = new MagnetarCall[](1);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.ExerciseOption),
            target: address(tOb),
            value: 0,
            call: abi.encodeWithSelector(TapiocaOptionsBrokerMock.exerciseOption.selector, 0, address(paymentToken), 1 ether)
        });
        magnetar.burst(calls);

        uint256 balanceOfTap = tapOft.balanceOf(address(this));
        assertEq(balanceOfTap, 1 ether);
    }
}
