// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {LZSendParam} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarTestHelper, MagnetarSetupData, TestBigBangData, TestSingularityData} from "./MagnetarTestHelper.sol";
import {
    MagnetarAction,
    MagnetarModule,
    MagnetarCall,
    MagnetarWithdrawData,
    LockAndParticipateData,
    MintFromBBAndLendOnSGLData
} from "tapioca-periph/interfaces/periph/IMagnetar.sol";

import {ERC20PermitStruct} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {MagnetarOptionModule} from "tapioca-periph/Magnetar/modules/MagnetarOptionModule.sol";
import {MagnetarMintModule} from "tapioca-periph/Magnetar/modules/MagnetarMintModule.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IOptionsLockData} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ICommonExternalContracts, IDepositData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {IOptionsParticipateData} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {IRemoveAndRepay, IMintData} from "tapioca-periph/interfaces/oft/IUsdo.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {IPermit} from "tapioca-periph/interfaces/common/IPermit.sol";

import {TapiocaOptionsLiquidityProvisionMock} from "../../mocks/TapiocaOptionsLiquidityProvisionMock.sol";
import {TapiocaOptionsBrokerMock} from "../../mocks/TapiocaOptionsBrokerMock.sol";
import {TapOftMock} from "../../mocks/TapOftMock.sol";
import {ERC721Mock} from "../../mocks/ERC721Mock.sol";

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

        clusterA.updateContract(0, address(tOLPMock), true);
        clusterA.updateContract(0, address(tOB), true);
    }

    function createLockAndParticipateData(address user, address singularity, address magnetar) private returns (LockAndParticipateData memory data) {
        return LockAndParticipateData({
            user: user,
            singularity: singularity,
            magnetar: magnetar,
            lockData: IOptionsLockData({
                lock: false,
                target: address(0),
                lockDuration: 0,
                amount: 0,
                fraction: 0
            }),
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
                collateralDepositData: IDepositData({
                    deposit: false,
                    amount: depositAmount
                })
            }),
            depositData: IDepositData({
                deposit: false,
                amount: depositAmount
            }),
            lockData: IOptionsLockData({
                lock: false,
                target: address(0),
                lockDuration: 0,
                amount: 0,
                fraction: 0
            }),
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
        MintFromBBAndLendOnSGLData memory _params =
        _createMintFromBBAndLendOnSGLData(
            address(this), tokenAmount_ + mintAmount_, 0, tokenAmount_, address(magnetarA), address(sgl), address(bb), address(marketHelper)
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
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(magnetarA), type(uint200).max, uint48(block.timestamp)); // this is needed for Pearlmit.allowance check on market
        pearlmit.approve(1155, address(yieldBox), collateralAId, address(bb), type(uint200).max, uint48(block.timestamp)); // Atomic approval
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

     // -----------------------0
    //
    // Tests
    //
    // -----------------------
    function test_lockAndParticipate_validation() public {
        address randomAddr = makeAddr("not_whitelisted");
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        LockAndParticipateData memory _params = createLockAndParticipateData(
            address(this), randomAddr, address(magnetarA)
        );
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

        _params.singularity = address(sgl);
        _params.magnetar = randomAddr;
        lockAndParticipateData =
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

    function test_lockAndParticipate_lock_validation() public {
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // test market
        LockAndParticipateData memory _params = createLockAndParticipateData(
            address(this), address(sgl), address(magnetarA)
        );
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
        LockAndParticipateData memory _paramsLock = createLockAndParticipateData(
            address(this), address(sgl), address(magnetarA)
        );
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
        MagnetarCall[] memory calls = new MagnetarCall[](1);

        // mint and lend
        _runLockPrerequisites();

        // test market
        LockAndParticipateData memory _paramsLock = createLockAndParticipateData(
            address(this), address(sgl), address(magnetarA)
        );
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