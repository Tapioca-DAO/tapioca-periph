// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {LZSendParam} from "tap-utils/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarTestHelper, MagnetarSetupData, TestBigBangData, TestSingularityData} from "./MagnetarTestHelper.t.sol";
import {
    MagnetarAction,
    MagnetarModule,
    MagnetarCall,
    MagnetarWithdrawData,
    DepositRepayAndRemoveCollateralFromMarketData,
    DepositAddCollateralAndBorrowFromMarketData,
    MintFromBBAndLendOnSGLData
} from "tap-utils/interfaces/periph/IMagnetar.sol";

import {ERC20PermitStruct} from "tap-utils/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarMintModule} from "tapioca-periph/Magnetar/modules/MagnetarMintModule.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IOptionsLockData} from "tap-utils/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ICommonExternalContracts, IDepositData} from "tap-utils/interfaces/common/ICommonData.sol";
import {IOptionsParticipateData} from "tap-utils/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {IPearlmit} from "tap-utils/interfaces/periph/IPearlmit.sol";
import {IPermit} from "tap-utils/interfaces/common/IPermit.sol";
import {IMintData} from "tap-utils/interfaces/oft/IUsdo.sol";

import {TapiocaOptionsLiquidityProvisionMock} from "../../mocks/TapiocaOptionsLiquidityProvisionMock.sol";
import {TapiocaOptionsBrokerMock} from "../../mocks/TapiocaOptionsBrokerMock.sol";
import {TapOftMock} from "../../mocks/TapOftMock.sol";
import {ERC721Mock} from "../../mocks/ERC721Mock.sol";

import {ERC20WithoutStrategy} from "yieldbox/strategies/ERC20WithoutStrategy.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MagnetarMintModuleTest is MagnetarTestHelper, IERC721Receiver {
    TapiocaOptionsLiquidityProvisionMock public tOLPMock;
    TapiocaOptionsBrokerMock public tOB;

    uint256 public sglAssetId;

    // -----------------------
    //
    // Setup
    //
    // -----------------------
    function setUp() public override {
        createCommonSetup();

        ERC20WithoutStrategy sglStrategy = createYieldBoxEmptyStrategy(address(yieldBox), address(sgl));
        sglAssetId = registerYieldBoxAsset(address(yieldBox), address(sgl), address(sglStrategy));

        tOLPMock = new TapiocaOptionsLiquidityProvisionMock(sglAssetId, address(yieldBox), IPearlmit(address(pearlmit)));

        TapOftMock tapOft = new TapOftMock();
        ERC721Mock oTAP = new ERC721Mock();
        tOB = new TapiocaOptionsBrokerMock(address(oTAP), address(tapOft), IPearlmit(address(pearlmit)));
        tOB.setTOLP(address(tOLPMock));

        clusterA.setRoleForContract(address(tOLPMock), keccak256("MAGNETAR_TAP_CALLEE"), true);
        clusterA.setRoleForContract(address(tOB), keccak256("MAGNETAR_TAP_CALLEE"), true);

        clusterB.setRoleForContract(address(tOLPMock), keccak256("MAGNETAR_TAP_CALLEE"), true);
        clusterB.setRoleForContract(address(tOB), keccak256("MAGNETAR_TAP_CALLEE"), true);
    }

    function _createMintFromBBAndLendOnSGLData(
        address user,
        uint256 lendAmount,
        uint256 mintAmount,
        uint256 depositAmount,
        address _magnetar,
        address _singularity,
        address _bigBang,
        address _marketHelper
    ) private returns (MintFromBBAndLendOnSGLData memory _params) {
        MagnetarWithdrawData memory _withdrawData = createEmptyWithdrawData();
        _params = MintFromBBAndLendOnSGLData({
            user: user,
            lendAmount: lendAmount,
            mintData: IMintData({
                mint: false,
                mintAmount: mintAmount,
                collateralDepositData: IDepositData({deposit: false, amount: depositAmount})
            }),
            depositData: IDepositData({deposit: false, amount: depositAmount}),
            lockData: IOptionsLockData({
                lock: false,
                target: address(0),
                tAsset: address(0),
                lockDuration: 0,
                amount: 0,
                fraction: 0,
                minDiscountOut: 0
            }),
            participateData: IOptionsParticipateData({participate: false, target: address(0), tOLPTokenId: 0}),
            externalContracts: ICommonExternalContracts({
                magnetar: _magnetar,
                singularity: _singularity,
                bigBang: _bigBang,
                marketHelper: _marketHelper
            })
        });
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // -----------------------0
    //
    // Tests
    //
    // -----------------------
    function test_mintFromBBAndLendOnSGL_validation() public {
        address randomAddr = makeAddr("not_whitelisted");
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        MintFromBBAndLendOnSGLData memory _params = _createMintFromBBAndLendOnSGLData(
            address(this), 0, 0, 0, randomAddr, address(sgl), address(bb), address(marketHelper)
        );
        bytes memory mintFromBBAndLendOnSGLData =
            abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.externalContracts.magnetar = address(magnetarA);
        _params.externalContracts.singularity = randomAddr;
        mintFromBBAndLendOnSGLData = abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.externalContracts.singularity = address(magnetarA);
        _params.externalContracts.bigBang = randomAddr;
        mintFromBBAndLendOnSGLData = abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.externalContracts.bigBang = address(magnetarA);
        _params.externalContracts.marketHelper = randomAddr;
        mintFromBBAndLendOnSGLData = abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.externalContracts.bigBang = address(magnetarA);
        _params.externalContracts.marketHelper = randomAddr;
        mintFromBBAndLendOnSGLData = abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.externalContracts.marketHelper = address(magnetarA);
        _params.lockData.target = randomAddr;
        mintFromBBAndLendOnSGLData = abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.lockData.target = address(magnetarA);
        _params.participateData.target = randomAddr;
        mintFromBBAndLendOnSGLData = abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);
    }

    function test_mintFromBBAndLendOnSGL_addCollateral() public {
        uint256 tokenAmount_ = 1 ether;
        {
            deal(address(collateralA), address(this), tokenAmount_);
        }

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        MintFromBBAndLendOnSGLData memory _params = _createMintFromBBAndLendOnSGLData(
            address(this), 0, 0, tokenAmount_, address(magnetarA), address(sgl), address(bb), address(marketHelper)
        );
        _params.mintData.mint = true;
        _params.mintData.collateralDepositData.deposit = true;
        _params.mintData.collateralDepositData.amount = tokenAmount_;

        bytes memory mintFromBBAndLendOnSGLData =
            abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });

        uint256 colSharesBefore = bb._userCollateralShare(address(this));

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)
        ); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(bb), type(uint200).max, uint48(block.timestamp)
        ); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = bb._userCollateralShare(address(this));
        assertGt(colSharesAfter, colSharesBefore);
    }

    function test_mintFromBBAndLendOnSGL_addCollateral_and_mint() public {
        uint256 tokenAmount_ = 1 ether;
        uint256 mintAmount_ = 0.5 ether;
        {
            deal(address(collateralA), address(this), tokenAmount_);
        }

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        MintFromBBAndLendOnSGLData memory _params = _createMintFromBBAndLendOnSGLData(
            address(this), 0, 0, tokenAmount_, address(magnetarA), address(sgl), address(bb), address(marketHelper)
        );
        _params.mintData.mint = true;
        _params.mintData.mintAmount = mintAmount_;
        _params.mintData.collateralDepositData.deposit = true;
        _params.mintData.collateralDepositData.amount = tokenAmount_;

        bytes memory mintFromBBAndLendOnSGLData =
            abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });

        uint256 colSharesBefore = bb._userCollateralShare(address(this));
        uint256 borrowPartBefore = bb._userBorrowPart(address(this));

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)
        ); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(bb), type(uint200).max, uint48(block.timestamp)
        ); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = bb._userCollateralShare(address(this));
        uint256 borrowPartAfter = bb._userBorrowPart(address(this));
        assertGt(colSharesAfter, colSharesBefore);
        assertGt(borrowPartAfter, borrowPartBefore);
    }

    function test_mintFromBBAndLendOnSGL_only_deposit() public {
        uint256 tokenAmount_ = 1 ether;
        {
            deal(address(assetA), address(this), tokenAmount_);
        }

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        MintFromBBAndLendOnSGLData memory _params = _createMintFromBBAndLendOnSGLData(
            address(this), 0, 0, tokenAmount_, address(magnetarA), address(sgl), address(bb), address(marketHelper)
        );
        _params.depositData.deposit = true;
        _params.depositData.amount = tokenAmount_;

        bytes memory mintFromBBAndLendOnSGLData =
            abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });

        uint256 assetABalanceBefore = yieldBox.balanceOf(address(this), assetAId);

        // manually deposit asset to YB
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        assetA.approve(address(pearlmit), type(uint256).max);

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 assetABalanceAfter = yieldBox.balanceOf(address(this), assetAId);
        assertGt(assetABalanceAfter, assetABalanceBefore);
    }

    function test_mintFromBBAndLendOnSGL_addCollateral_and_mint_and_depositExtra() public {
        uint256 tokenAmount_ = 1 ether;
        uint256 mintAmount_ = 0.5 ether;
        {
            deal(address(collateralA), address(this), tokenAmount_);
            deal(address(assetA), address(this), tokenAmount_);
        }

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        MintFromBBAndLendOnSGLData memory _params = _createMintFromBBAndLendOnSGLData(
            address(this), 0, 0, tokenAmount_, address(magnetarA), address(sgl), address(bb), address(marketHelper)
        );
        _params.mintData.mint = true;
        _params.mintData.mintAmount = mintAmount_;
        _params.mintData.collateralDepositData.deposit = true;
        _params.mintData.collateralDepositData.amount = tokenAmount_;
        _params.depositData.deposit = true;
        _params.depositData.amount = tokenAmount_;

        bytes memory mintFromBBAndLendOnSGLData =
            abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });

        uint256 colSharesBefore = bb._userCollateralShare(address(this));
        uint256 borrowPartBefore = bb._userBorrowPart(address(this));
        uint256 assetABalanceBefore = yieldBox.balanceOf(address(this), assetAId);

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)
        ); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(bb), type(uint200).max, uint48(block.timestamp)
        ); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        assetA.approve(address(pearlmit), type(uint256).max);

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = bb._userCollateralShare(address(this));
        uint256 borrowPartAfter = bb._userBorrowPart(address(this));
        uint256 assetABalanceAfter = yieldBox.balanceOf(address(this), assetAId);
        assertGt(assetABalanceAfter, assetABalanceBefore);
        assertGt(colSharesAfter, colSharesBefore);
        assertGt(borrowPartAfter, borrowPartBefore);
    }

    function test_mintFromBBAndLendOnSGL_addCollateral_mint_depositExtra_and_lend() public {
        uint256 tokenAmount_ = 1 ether;
        uint256 mintAmount_ = 0.5 ether;
        {
            deal(address(collateralA), address(this), tokenAmount_);
            deal(address(assetA), address(this), tokenAmount_);
        }

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        MintFromBBAndLendOnSGLData memory _params = _createMintFromBBAndLendOnSGLData(
            address(this),
            tokenAmount_ + mintAmount_,
            0,
            tokenAmount_,
            address(magnetarA),
            address(sgl),
            address(bb),
            address(marketHelper)
        );
        _params.mintData.mint = true;
        _params.mintData.mintAmount = mintAmount_;
        _params.mintData.collateralDepositData.deposit = true;
        _params.mintData.collateralDepositData.amount = tokenAmount_;
        _params.depositData.deposit = true;
        _params.depositData.amount = tokenAmount_;

        bytes memory mintFromBBAndLendOnSGLData =
            abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });

        uint256 colSharesBefore = bb._userCollateralShare(address(this));
        uint256 borrowPartBefore = bb._userBorrowPart(address(this));
        uint256 sglBalanceBefore = sgl.balanceOf(address(this));

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)
        ); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(bb), type(uint200).max, uint48(block.timestamp)
        ); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        assetA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(20, address(sgl), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check on market.allowedLend
        pearlmit.approve(1155, address(yieldBox), assetAId, address(sgl), type(uint200).max, uint48(block.timestamp)); // lend approval

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = bb._userCollateralShare(address(this));
        uint256 borrowPartAfter = bb._userBorrowPart(address(this));
        uint256 sglBalanceAfter = sgl.balanceOf(address(this));
        assertGt(colSharesAfter, colSharesBefore);
        assertGt(borrowPartAfter, borrowPartBefore);
        assertGt(sglBalanceAfter, sglBalanceBefore);
    }

    function test_mintFromBBAndLendOnSGL_addCollateral_mint_depositExtra_lend_and_lock() public {
        vm.skip(true);
        uint256 tokenAmount_ = 1 ether;
        uint256 mintAmount_ = 0.5 ether;
        {
            deal(address(collateralA), address(this), tokenAmount_);
            deal(address(assetA), address(this), tokenAmount_);
        }

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        MintFromBBAndLendOnSGLData memory _params = _createMintFromBBAndLendOnSGLData(
            address(this),
            tokenAmount_ + mintAmount_,
            0,
            tokenAmount_,
            address(magnetarA),
            address(sgl),
            address(bb),
            address(marketHelper)
        );
        _params.mintData.mint = true;
        _params.mintData.mintAmount = mintAmount_;
        _params.mintData.collateralDepositData.deposit = true;
        _params.mintData.collateralDepositData.amount = tokenAmount_;
        _params.depositData.deposit = true;
        _params.depositData.amount = tokenAmount_;
        _params.lockData.lock = true;
        _params.lockData.target = address(tOLPMock);

        bytes memory mintFromBBAndLendOnSGLData =
            abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });

        uint256 colSharesBefore = bb._userCollateralShare(address(this));
        uint256 borrowPartBefore = bb._userBorrowPart(address(this));
        uint256 tolpBalanceBefore = tOLPMock.balanceOf(address(this));

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)
        ); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(bb), type(uint200).max, uint48(block.timestamp)
        ); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        assetA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(20, address(sgl), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check on market.allowedLend
        pearlmit.approve(1155, address(yieldBox), assetAId, address(sgl), type(uint200).max, uint48(block.timestamp)); // lend approval
        sgl.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(
            1155, address(yieldBox), sglAssetId, address(magnetarA), type(uint200).max, uint48(block.timestamp)
        ); // lend approval

        magnetarA.burst{value: 0}(calls);

        sgl.approve(address(pearlmit), 0);
        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = bb._userCollateralShare(address(this));
        uint256 borrowPartAfter = bb._userBorrowPart(address(this));
        uint256 tolpBalanceAfter = tOLPMock.balanceOf(address(this));
        assertGt(colSharesAfter, colSharesBefore);
        assertGt(borrowPartAfter, borrowPartBefore);
        assertGt(tolpBalanceAfter, tolpBalanceBefore);
    }

    function test_mintFromBBAndLendOnSGL_addCollateral_mint_depositExtra_lend_lock_and_participate() public {
        vm.skip(true);
        uint256 tokenAmount_ = 1 ether;
        uint256 mintAmount_ = 0.5 ether;
        {
            deal(address(collateralA), address(this), tokenAmount_);
            deal(address(assetA), address(this), tokenAmount_);
        }

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        MintFromBBAndLendOnSGLData memory _params = _createMintFromBBAndLendOnSGLData(
            address(this),
            tokenAmount_ + mintAmount_,
            0,
            tokenAmount_,
            address(magnetarA),
            address(sgl),
            address(bb),
            address(marketHelper)
        );
        _params.mintData.mint = true;
        _params.mintData.mintAmount = mintAmount_;
        _params.mintData.collateralDepositData.deposit = true;
        _params.mintData.collateralDepositData.amount = tokenAmount_;
        _params.depositData.deposit = true;
        _params.depositData.amount = tokenAmount_;
        _params.lockData.lock = true;
        _params.lockData.target = address(tOLPMock);
        _params.participateData.participate = true;
        _params.participateData.target = address(tOB);

        bytes memory mintFromBBAndLendOnSGLData =
            abi.encodeWithSelector(MagnetarMintModule.mintBBLendSGLLockTOLP.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.MintModule),
            target: address(magnetarA),
            value: 0,
            call: mintFromBBAndLendOnSGLData
        });

        uint256 colSharesBefore = bb._userCollateralShare(address(this));
        uint256 borrowPartBefore = bb._userBorrowPart(address(this));

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)
        ); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(bb), type(uint200).max, uint48(block.timestamp)
        ); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        assetA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(20, address(sgl), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check on market.allowedLend
        pearlmit.approve(1155, address(yieldBox), assetAId, address(sgl), type(uint200).max, uint48(block.timestamp)); // lend approval
        sgl.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(
            1155, address(yieldBox), sglAssetId, address(magnetarA), type(uint200).max, uint48(block.timestamp)
        ); // lend approval
        pearlmit.approve(721, address(tOLPMock), 1, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // lend approval
        tOLPMock.setApprovalForAll(address(pearlmit), true);

        magnetarA.burst{value: 0}(calls);

        sgl.approve(address(pearlmit), 0);
        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));

        uint256 colSharesAfter = bb._userCollateralShare(address(this));
        uint256 borrowPartAfter = bb._userBorrowPart(address(this));
        assertGt(colSharesAfter, colSharesBefore);
        assertGt(borrowPartAfter, borrowPartBefore);
    }
}
