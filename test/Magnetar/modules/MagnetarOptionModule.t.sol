// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {LZSendParam} from "tap-utils/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarTestHelper, MagnetarSetupData, TestBigBangData, TestSingularityData} from "./MagnetarTestHelper.t.sol";
import {
    MagnetarAction,
    MagnetarModule,
    MagnetarCall,
    MagnetarWithdrawData,
    LockAndParticipateData,
    MintFromBBAndLendOnSGLData,
    ExitPositionAndRemoveCollateralData
} from "tap-utils/interfaces/periph/IMagnetar.sol";

import {ERC20PermitStruct} from "tap-utils/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarOptionModule} from "tapioca-periph/Magnetar/modules/MagnetarOptionModule.sol";
import {MagnetarMintModule} from "tapioca-periph/Magnetar/modules/MagnetarMintModule.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {
    IOptionsLockData,
    IOptionsUnlockData
} from "tap-utils/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ICommonExternalContracts, IDepositData} from "tap-utils/interfaces/common/ICommonData.sol";
import {IOptionsParticipateData, IOptionsExitData} from "tap-utils/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {IRemoveAndRepay, IMintData} from "tap-utils/interfaces/oft/IUsdo.sol";
import {IPearlmit} from "tap-utils/interfaces/periph/IPearlmit.sol";
import {IPermit} from "tap-utils/interfaces/common/IPermit.sol";

import {TapiocaOptionsLiquidityProvisionMock} from "../../mocks/TapiocaOptionsLiquidityProvisionMock.sol";
import {TapiocaOptionsBrokerMock} from "../../mocks/TapiocaOptionsBrokerMock.sol";
import {TapOftMock} from "../../mocks/TapOftMock.sol";
import {ERC721Mock} from "../../mocks/ERC721Mock.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

import {ERC20WithoutStrategy} from "yieldbox/strategies/ERC20WithoutStrategy.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MagnetarOptionModuleTest is MagnetarTestHelper, IERC721Receiver {
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

        pearlmit.approve(1155, address(yieldBox), assetAId, address(bb), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check on market
    }

    function createLockAndParticipateData(address user, address singularity, address magnetar, address yieldBox)
        private
        returns (LockAndParticipateData memory data)
    {
        return LockAndParticipateData({
            user: user,
            tSglToken: singularity,
            yieldBox: yieldBox,
            magnetar: magnetar,
            lockData: IOptionsLockData({lock: false, target: address(0), tAsset:address(0), lockDuration: 0, amount: 0, fraction: 0, minDiscountOut: 0}),
            participateData: IOptionsParticipateData({
                participate: false,
                target: address(0),
                tOLPTokenId: 0

            }),
            value: 0
        });
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
            lockData: IOptionsLockData({lock: false, target: address(0), tAsset:address(0), lockDuration: 0, amount: 0, fraction: 0, minDiscountOut: 0}),
            participateData: IOptionsParticipateData({
                participate: false,
                target: address(0),
                tOLPTokenId: 0

            }),
            externalContracts: ICommonExternalContracts({
                magnetar: _magnetar,
                singularity: _singularity,
                bigBang: _bigBang,
                marketHelper: _marketHelper
            })
        });
    }

    function _runLockPrerequisites() public {
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // get SGL tokens
        uint256 tokenAmount_ = 1 ether;
        uint256 mintAmount_ = 0.5 ether;
        {
            deal(address(collateralA), address(this), tokenAmount_);
            deal(address(assetA), address(this), tokenAmount_);
        }

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

        //approvals for deposit & collateral add
        pearlmit.approve(20, address(collateralA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        collateralA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)
        ); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(
            1155, address(yieldBox), collateralAId, address(bb), type(uint200).max, uint48(block.timestamp)
        ); // Atomic approval
        pearlmit.approve(
            1155, address(yieldBox), 6, address(tOLPMock), type(uint200).max, uint48(block.timestamp)
        ); // Atomic approval
        _setYieldBoxApproval(yieldBox, address(pearlmit));
        pearlmit.approve(20, address(assetA), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // Atomic approval
        assetA.approve(address(pearlmit), type(uint256).max);
        pearlmit.approve(20, address(sgl), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check on market.allowedLend
        pearlmit.approve(1155, address(yieldBox), assetAId, address(sgl), type(uint200).max, uint48(block.timestamp)); // lend approval

        magnetarA.burst{value: 0}(calls);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function createExitPositionAndRemoveCollateralData(
        address user,
        address _magnetar,
        address _singularity,
        address _bigBang,
        address _marketHelper
    ) private returns (ExitPositionAndRemoveCollateralData memory _params) {
        return ExitPositionAndRemoveCollateralData({
            user: user,
            externalData: ICommonExternalContracts({
                magnetar: _magnetar,
                singularity: _singularity,
                bigBang: _bigBang,
                marketHelper: _marketHelper
            }),
            removeAndRepayData: IRemoveAndRepay({
                removeAssetFromSGL: false,
                removeAmount: 0,
                repayAssetOnBB: false,
                repayAmount: 0,
                removeCollateralFromBB: false,
                collateralAmount: 0,
                exitData: IOptionsExitData({exit: false, target: address(0), oTAPTokenID: 0}),
                unlockData: IOptionsUnlockData({unlock: false, target: address(0), tokenId: 0}),
                assetWithdrawData: createEmptyWithdrawData(),
                collateralWithdrawData: createEmptyWithdrawData()
            })
        });
    }

    function _lockAndParticipatePrerequisites() private {
        // mint and lend
        _runLockPrerequisites();
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // lock and participate
        LockAndParticipateData memory _paramsLock =
            createLockAndParticipateData(address(this), address(sgl), address(magnetarA), address(yieldBox));
        _paramsLock.lockData.lock = true;
        _paramsLock.lockData.target = address(tOLPMock);
        _paramsLock.lockData.fraction = sgl.balanceOf(address(this));
        _paramsLock.participateData.participate = true;
        _paramsLock.participateData.target = address(tOB);
        bytes memory lockAndParticipateData =
            abi.encodeWithSelector(MagnetarOptionModule.lockAndParticipate.selector, _paramsLock);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: lockAndParticipateData
        });

        {
            pearlmit.approve(20, address(sgl), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp));
            sgl.approve(address(pearlmit), type(uint256).max);
            pearlmit.approve(721, address(tOLPMock), 1, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // lend approval
            tOLPMock.setApprovalForAll(address(pearlmit), true);
        }

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));
    }

    // -----------------------0
    //
    // Tests
    //
    // -----------------------
    function test_exitPositionAndRemoveCollateral_validation() public {
        address randomAddr = makeAddr("not_whitelisted");
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        ExitPositionAndRemoveCollateralData memory _params = createExitPositionAndRemoveCollateralData(
            address(this), randomAddr, address(sgl), address(bb), address(marketHelper)
        );
        bytes memory exitPositionAndRemoveCollateraleData =
            abi.encodeWithSelector(MagnetarOptionModule.exitPositionAndRemoveCollateral.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: exitPositionAndRemoveCollateraleData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.externalData.magnetar = address(magnetarA);
        _params.externalData.singularity = randomAddr;
        exitPositionAndRemoveCollateraleData =
            abi.encodeWithSelector(MagnetarOptionModule.exitPositionAndRemoveCollateral.selector, _params);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: exitPositionAndRemoveCollateraleData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.externalData.singularity = address(sgl);
        _params.externalData.bigBang = randomAddr;
        exitPositionAndRemoveCollateraleData =
            abi.encodeWithSelector(MagnetarOptionModule.exitPositionAndRemoveCollateral.selector, _params);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: exitPositionAndRemoveCollateraleData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.externalData.bigBang = address(bb);
        _params.externalData.marketHelper = randomAddr;
        exitPositionAndRemoveCollateraleData =
            abi.encodeWithSelector(MagnetarOptionModule.exitPositionAndRemoveCollateral.selector, _params);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: exitPositionAndRemoveCollateraleData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);
    }

    function test_exitPositionAndRemoveCollateral_remove() public {
        _runLockPrerequisites();

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        ExitPositionAndRemoveCollateralData memory _params = createExitPositionAndRemoveCollateralData(
            address(this), address(magnetarA), address(sgl), address(bb), address(marketHelper)
        );
        _params.removeAndRepayData.removeAssetFromSGL = true;
        _params.removeAndRepayData.removeAmount = 1 ether;

        bytes memory exitPositionAndRemoveCollateraleData =
            abi.encodeWithSelector(MagnetarOptionModule.exitPositionAndRemoveCollateral.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: exitPositionAndRemoveCollateraleData
        });

        uint256 sglBalanceBefore = sgl.balanceOf(address(this));
        magnetarA.burst{value: 0}(calls);
        uint256 sglBalanceAfter = sgl.balanceOf(address(this));

        assertGt(sglBalanceBefore, sglBalanceAfter);
    }

    function test_exitPositionAndRemoveCollateral_remove_repay() public {
        vm.skip(true);
        _runLockPrerequisites();

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        ExitPositionAndRemoveCollateralData memory _params = createExitPositionAndRemoveCollateralData(
            address(this), address(magnetarA), address(sgl), address(bb), address(marketHelper)
        );
        _params.removeAndRepayData.removeAssetFromSGL = true;
        _params.removeAndRepayData.removeAmount = 1 ether;
        _params.removeAndRepayData.repayAssetOnBB = true;
        _params.removeAndRepayData.repayAmount = 1 ether - 1;

        bytes memory exitPositionAndRemoveCollateraleData =
            abi.encodeWithSelector(MagnetarOptionModule.exitPositionAndRemoveCollateral.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: exitPositionAndRemoveCollateraleData
        });

        pearlmit.approve(20, address(bb), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp));
        _setYieldBoxApproval(yieldBox, address(bb));

        uint256 sglBalanceBefore = sgl.balanceOf(address(this));
        uint256 borrowPartBefore = bb._userBorrowPart(address(this));
        magnetarA.burst{value: 0}(calls);
        uint256 sglBalanceAfter = sgl.balanceOf(address(this));
        uint256 borrowPartAfter = bb._userBorrowPart(address(this));

        _setYieldBoxRevoke(yieldBox, address(bb));

        assertGt(sglBalanceBefore, sglBalanceAfter);
        assertGt(borrowPartBefore, borrowPartAfter);
    }

    function test_exitPositionAndRemoveCollateral_remove_repay_removeCollateral() public {
        vm.skip(true);
        _runLockPrerequisites();

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        ExitPositionAndRemoveCollateralData memory _params = createExitPositionAndRemoveCollateralData(
            address(this), address(magnetarA), address(sgl), address(bb), address(marketHelper)
        );
        _params.removeAndRepayData.removeAssetFromSGL = true;
        _params.removeAndRepayData.removeAmount = 1 ether;
        _params.removeAndRepayData.repayAssetOnBB = true;
        _params.removeAndRepayData.repayAmount = 1 ether - 1;
        _params.removeAndRepayData.removeCollateralFromBB = true;
        _params.removeAndRepayData.collateralAmount = 0.5 ether;

        bytes memory exitPositionAndRemoveCollateraleData =
            abi.encodeWithSelector(MagnetarOptionModule.exitPositionAndRemoveCollateral.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: exitPositionAndRemoveCollateraleData
        });

        pearlmit.approve(20, address(bb), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp));
        _setYieldBoxApproval(yieldBox, address(bb));

        uint256 collateralShareBefore = bb._userCollateralShare(address(this));
        magnetarA.burst{value: 0}(calls);
        uint256 collateralShareAfter = bb._userCollateralShare(address(this));

        _setYieldBoxRevoke(yieldBox, address(bb));

        assertGt(collateralShareBefore, collateralShareAfter);
    }

    function test_exitPositionAndRemoveCollateral_remove_repay_removeCollateral_withdrawCollateral() public {
        vm.skip(true);
        _runLockPrerequisites();

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        ExitPositionAndRemoveCollateralData memory _params = createExitPositionAndRemoveCollateralData(
            address(this), address(magnetarA), address(sgl), address(bb), address(marketHelper)
        );
        _params.removeAndRepayData.removeAssetFromSGL = true;
        _params.removeAndRepayData.removeAmount = 1 ether;
        _params.removeAndRepayData.repayAssetOnBB = true;
        _params.removeAndRepayData.repayAmount = 1 ether - 1;
        _params.removeAndRepayData.removeCollateralFromBB = true;
        _params.removeAndRepayData.collateralAmount = 0.5 ether;
        _params.removeAndRepayData.collateralWithdrawData.yieldBox = address(yieldBox);
        _params.removeAndRepayData.collateralWithdrawData.withdraw = true;
        _params.removeAndRepayData.collateralWithdrawData.assetId = bb._collateralId();
        _params.removeAndRepayData.collateralWithdrawData.amount = 0.5 ether;

        bytes memory exitPositionAndRemoveCollateraleData =
            abi.encodeWithSelector(MagnetarOptionModule.exitPositionAndRemoveCollateral.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: exitPositionAndRemoveCollateraleData
        });

        pearlmit.approve(20, address(bb), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp));
        _setYieldBoxApproval(yieldBox, address(bb));

        address _collateral = bb._collateral();
        uint256 balanceBefore = ERC20Mock(_collateral).balanceOf(address(this));
        uint256 collateralShareBefore = bb._userCollateralShare(address(this));
        magnetarA.burst{value: 0}(calls);
        uint256 collateralShareAfter = bb._userCollateralShare(address(this));
        uint256 balanceAfter = ERC20Mock(_collateral).balanceOf(address(this));

        _setYieldBoxRevoke(yieldBox, address(bb));

        assertGt(collateralShareBefore, collateralShareAfter);
        assertGt(balanceAfter, balanceBefore);
    }

    function test_exitPositionAndRemoveCollateral_remove_repay_removeCollateral_withdrawCollateral_withdrawAsset()
        public
    {
        _runLockPrerequisites();

        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        ExitPositionAndRemoveCollateralData memory _params = createExitPositionAndRemoveCollateralData(
            address(this), address(magnetarA), address(sgl), address(bb), address(marketHelper)
        );
        _params.removeAndRepayData.removeAssetFromSGL = true;
        _params.removeAndRepayData.removeAmount = 1 ether;
        _params.removeAndRepayData.repayAssetOnBB = false;
        _params.removeAndRepayData.removeCollateralFromBB = true;
        _params.removeAndRepayData.collateralAmount = 0.05 ether;
        _params.removeAndRepayData.collateralWithdrawData.yieldBox = address(yieldBox);
        _params.removeAndRepayData.collateralWithdrawData.withdraw = true;
        _params.removeAndRepayData.collateralWithdrawData.assetId = bb._collateralId();
        _params.removeAndRepayData.collateralWithdrawData.amount = 0.05 ether;
        _params.removeAndRepayData.assetWithdrawData.yieldBox = address(yieldBox);
        _params.removeAndRepayData.assetWithdrawData.withdraw = true;
        _params.removeAndRepayData.assetWithdrawData.assetId = bb._assetId();
        _params.removeAndRepayData.assetWithdrawData.amount = 0.5 ether;

        bytes memory exitPositionAndRemoveCollateraleData =
            abi.encodeWithSelector(MagnetarOptionModule.exitPositionAndRemoveCollateral.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: exitPositionAndRemoveCollateraleData
        });

        pearlmit.approve(20, address(bb), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp));
        _setYieldBoxApproval(yieldBox, address(magnetarA));
        _setYieldBoxApproval(yieldBox, address(bb));

        address _collateral = bb._collateral();
        uint256 balanceBefore = ERC20Mock(_collateral).balanceOf(address(this));
        uint256 collateralShareBefore = bb._userCollateralShare(address(this));
        magnetarA.burst{value: 0}(calls);
        uint256 collateralShareAfter = bb._userCollateralShare(address(this));
        uint256 balanceAfter = ERC20Mock(_collateral).balanceOf(address(this));

        _setYieldBoxRevoke(yieldBox, address(bb));
        _setYieldBoxRevoke(yieldBox, address(magnetarA));

        assertGt(collateralShareBefore, collateralShareAfter);
        assertGt(balanceAfter, balanceBefore);
    }

    function test_lockAndParticipate_validation() public {
        address randomAddr = makeAddr("not_whitelisted");
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        LockAndParticipateData memory _params =
            createLockAndParticipateData(address(this), randomAddr, address(magnetarA), address(yieldBox));
        bytes memory lockAndParticipateData =
            abi.encodeWithSelector(MagnetarOptionModule.lockAndParticipate.selector, _params);

        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: lockAndParticipateData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);

        _params.tSglToken = address(sgl);
        _params.magnetar = randomAddr;
        lockAndParticipateData = abi.encodeWithSelector(MagnetarOptionModule.lockAndParticipate.selector, _params);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: lockAndParticipateData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);
    }

    function test_lockAndParticipate_lock_validation() public {
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        LockAndParticipateData memory _params =
            createLockAndParticipateData(address(this), address(sgl), address(magnetarA), address(yieldBox));
        _params.lockData.lock = true;
        bytes memory lockAndParticipateData =
            abi.encodeWithSelector(MagnetarOptionModule.lockAndParticipate.selector, _params);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: lockAndParticipateData
        });
        vm.expectRevert();
        magnetarA.burst{value: 0}(calls);
    }

    function test_lockAndParticipate_lock_only() public {
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // mint and lend
        _runLockPrerequisites();

        // test market
        LockAndParticipateData memory _paramsLock =
            createLockAndParticipateData(address(this), address(sgl), address(magnetarA), address(yieldBox));
        _paramsLock.lockData.lock = true;
        _paramsLock.lockData.target = address(tOLPMock);
        _paramsLock.lockData.fraction = sgl.balanceOf(address(this));
        bytes memory lockAndParticipateData =
            abi.encodeWithSelector(MagnetarOptionModule.lockAndParticipate.selector, _paramsLock);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: lockAndParticipateData
        });

        {
            pearlmit.approve(20, address(sgl), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp));
            sgl.approve(address(pearlmit), type(uint256).max);
        }

        uint256 tolpBalanceBefore = tOLPMock.balanceOf(address(this));

        magnetarA.burst{value: 0}(calls);

        uint256 tolpBalanceAfter = tOLPMock.balanceOf(address(this));
        assertGt(tolpBalanceAfter, tolpBalanceBefore);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));
    }

    function test_lockAndParticipate_lock_and_participate() public {
        vm.skip(true);
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // mint and lend
        _runLockPrerequisites();

        // test market
        LockAndParticipateData memory _paramsLock =
            createLockAndParticipateData(address(this), address(sgl), address(magnetarA), address(yieldBox));
        _paramsLock.lockData.lock = true;
        _paramsLock.lockData.target = address(tOLPMock);
        _paramsLock.lockData.fraction = sgl.balanceOf(address(this));
        _paramsLock.participateData.participate = true;
        _paramsLock.participateData.target = address(tOB);
        bytes memory lockAndParticipateData =
            abi.encodeWithSelector(MagnetarOptionModule.lockAndParticipate.selector, _paramsLock);
        calls[0] = MagnetarCall({
            id: uint8(MagnetarAction.OptionModule),
            target: address(magnetarA),
            value: 0,
            call: lockAndParticipateData
        });

        {
            pearlmit.approve(20, address(sgl), 0, address(magnetarA), type(uint200).max, uint48(block.timestamp));
            sgl.approve(address(pearlmit), type(uint256).max);
            pearlmit.approve(721, address(tOLPMock), 1, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // lend approval
            tOLPMock.setApprovalForAll(address(pearlmit), true);
        }

        magnetarA.burst{value: 0}(calls);

        collateralA.approve(address(pearlmit), 0);
        _setYieldBoxRevoke(yieldBox, address(pearlmit));
    }
}
