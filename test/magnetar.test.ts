import { expect } from 'chai';
import hre, { ethers, config } from 'hardhat';
import { BN, register, getSGLPermitSignature } from './test.utils';
import { signTypedMessage } from 'eth-sig-util';
import { fromRpcSig } from 'ethereumjs-utils';
import {
    loadFixture,
    takeSnapshot,
} from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import LZEndpointMockArtifact from '../gitsub_tapioca-sdk/src/artifacts/tapioca-mocks/LZEndpointMock.json';
import SingularityArtifact from '../gitsub_tapioca-sdk/src/artifacts/tapioca-bar/Singularity.json';
import TapiocaOFTArtifact from '../gitsub_tapioca-sdk/src/artifacts/tapiocaz/TapiocaOFT.json';

import {
    LiquidationQueue__factory,
    SGLLendingBorrowing__factory,
    SGLLiquidation__factory,
    Singularity,
    USDO__factory,
} from '../gitsub_tapioca-sdk/src/typechain/Tapioca-Bar';
import {
    ERC20WithoutStrategy__factory,
    YieldBox,
} from '../gitsub_tapioca-sdk/src/typechain/YieldBox';
import {
    ERC20Mock__factory,
    LZEndpointMock__factory,
    OracleMock__factory,
} from '../gitsub_tapioca-sdk/src/typechain/tapioca-mocks';
import {
    BaseTOFT,
    TapiocaOFT__factory,
} from 'tapioca-sdk/dist/typechain/TapiocaZ';

const MAX_DEADLINE = 9999999999999;

const symbol = 'MTKN';
const version = '1';

describe('MagnetarV2', () => {
    describe('withdrawTo()', () => {
        it('should test withdrawTo', async () => {
            const {
                deployer,
                eoa1,
                yieldBox,
                createTokenEmptyStrategy,
                deployCurveStableToUsdoBidder,
                usd0,
                bar,
                __wethUsdcPrice,
                wethUsdcOracle,
                weth,
                wethAssetId,
                mediumRiskMC,
                usdc,
                magnetar,
                initContracts,
                timeTravel
            } = await loadFixture(register);

            const usdoStratregy = await bar.emptyStrategies(usd0.address);
            const usdoAssetId = await yieldBox.ids(
                1,
                usd0.address,
                usdoStratregy,
                0,
            );

            //Deploy & set Singularity
            const SGLLiquidation = new SGLLiquidation__factory(deployer);
            const _sglLiquidationModule = await SGLLiquidation.deploy();

            const SGLLendingBorrowing = new SGLLendingBorrowing__factory(deployer);
            const _sglLendingBorrowingModule = await SGLLendingBorrowing.deploy();

            const collateralSwapPath = [usd0.address, weth.address];

            const newPrice = __wethUsdcPrice.div(1000000);
            await wethUsdcOracle.set(newPrice);

            const sglData = new ethers.utils.AbiCoder().encode(
                [
                    'address',
                    'address',
                    'address',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                ],
                [
                    _sglLiquidationModule.address,
                    _sglLendingBorrowingModule.address,
                    bar.address,
                    usd0.address,
                    usdoAssetId,
                    weth.address,
                    wethAssetId,
                    wethUsdcOracle.address,
                    ethers.utils.parseEther('1'),
                ],
            );
            await bar.registerSingularity(mediumRiskMC.address, sglData, true);
            const wethUsdoSingularity = new ethers.Contract(
                await bar.clonesOf(
                    mediumRiskMC.address,
                    (await bar.clonesOfCount(mediumRiskMC.address)).sub(1),
                ),
                SingularityArtifact.abi,
                ethers.provider,
            );

            //Deploy & set LiquidationQueue
            await usd0.setMinterStatus(wethUsdoSingularity.address, true);
            await usd0.setBurnerStatus(wethUsdoSingularity.address, true);

            const LiquidationQueue = new LiquidationQueue__factory(deployer);
            const liquidationQueue = await LiquidationQueue.deploy();

            const feeCollector = new ethers.Wallet(
                ethers.Wallet.createRandom().privateKey,
                ethers.provider,
            );

            const { stableToUsdoBidder } = await deployCurveStableToUsdoBidder(
                deployer,
                bar,
                usdc,
                usd0,
            );

            const LQ_META = {
                activationTime: 600, // 10min
                minBidAmount: ethers.BigNumber.from((1e18).toString()).mul(200), // 200 USDC
                closeToMinBidAmount: ethers.BigNumber.from((1e18).toString()).mul(
                    202,
                ),
                defaultBidAmount: ethers.BigNumber.from((1e18).toString()).mul(400), // 400 USDC
                feeCollector: feeCollector.address,
                bidExecutionSwapper: ethers.constants.AddressZero,
                usdoSwapper: stableToUsdoBidder.address,
            };
            await liquidationQueue.init(LQ_META, wethUsdoSingularity.address);

            const payload = wethUsdoSingularity.interface.encodeFunctionData(
                'setLiquidationQueue',
                [liquidationQueue.address],
            );

            await (
                await bar.executeMarketFn(
                    [wethUsdoSingularity.address],
                    [payload],
                    true,
                )
            ).wait();

            const usdoAmount = ethers.BigNumber.from((1e18).toString()).mul(10);
            const usdoShare = await yieldBox.toShare(
                usdoAssetId,
                usdoAmount,
                false,
            );
            await usd0.mint(deployer.address, usdoAmount);

            const depositAssetEncoded = yieldBox.interface.encodeFunctionData(
                'depositAsset',
                [usdoAssetId, deployer.address, deployer.address, 0, usdoShare],
            );

            const sglLendEncoded = wethUsdoSingularity.interface.encodeFunctionData(
                'addAsset',
                [deployer.address, deployer.address, false, usdoShare],
            );

            await usd0.approve(magnetar.address, ethers.constants.MaxUint256);
            await usd0.approve(yieldBox.address, ethers.constants.MaxUint256);
            await usd0.approve(wethUsdoSingularity.address, ethers.constants.MaxUint256);
            await yieldBox.setApprovalForAll(deployer.address, true);
            await yieldBox.setApprovalForAll(wethUsdoSingularity.address, true)
            await yieldBox.setApprovalForAll(magnetar.address, true)
            await weth.approve(yieldBox.address, ethers.constants.MaxUint256);
            await weth.approve(magnetar.address, ethers.constants.MaxUint256);

            const calls = [
                {
                    id: 100,
                    target: yieldBox.address,
                    value: 0,
                    allowFailure: false,
                    call: depositAssetEncoded,
                },
                {
                    id: 203,
                    target: wethUsdoSingularity.address,
                    value: 0,
                    allowFailure: false,
                    call: sglLendEncoded,
                },
            ];

            await magnetar.connect(deployer).burst(calls);

            const ybBalance = await yieldBox.balanceOf(
                deployer.address,
                usdoAssetId,
            );
            expect(ybBalance.eq(0)).to.be.true;

            const sglBalance = await wethUsdoSingularity.balanceOf(
                deployer.address,
            );
            expect(sglBalance.gt(0)).to.be.true;


            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            await timeTravel(86401);
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(1);
            await weth.freeMint(wethMintVal);

            await wethUsdoSingularity
                .connect(deployer)
                .approveBorrow(magnetar.address, ethers.constants.MaxUint256);




            hre.tracer.enabled = true;
            const borrowFn = magnetar.interface.encodeFunctionData(
                'depositAddCollateralAndBorrow',
                [
                    wethUsdoSingularity.address,
                    deployer.address,
                    wethMintVal,
                    0,
                    true,
                    true,
                    false,
                    encodeMagnetarWithdrawData(false, 0, eoa1.address, '0x00'),
                ],
            );
            hre.tracer.enabled = false;

            let borrowPart = await wethUsdoSingularity.userBorrowPart(deployer.address);
            expect(borrowPart.eq(0)).to.be.true;
            await magnetar.connect(deployer).burst(
                [
                    {
                        id: 206,
                        target: magnetar.address,
                        value: ethers.utils.parseEther('2'),
                        allowFailure: false,
                        call: borrowFn,
                    },
                ],
                {
                    value: ethers.utils.parseEther('2'),
                },
            );

            const collateralBalance = await wethUsdoSingularity.userCollateralShare(deployer.address);
            const collateralAmpunt = await yieldBox.toAmount(wethAssetId, collateralBalance, false);
            expect(collateralAmpunt.eq(wethMintVal)).to.be.true;

            const totalAsset = await wethUsdoSingularity.totalSupply();

            await wethUsdoSingularity.connect(deployer).borrow(deployer.address, deployer.address, borrowAmount);

            borrowPart = await wethUsdoSingularity.userBorrowPart(deployer.address);
            expect(borrowPart.gte(borrowAmount)).to.be.true;


            const receiverSplit = deployer.address.split('0x');
            await magnetar.withdrawTo(yieldBox.address, deployer.address, usdoAssetId, 0, '0x'.concat(receiverSplit[1].padStart(64, '0')), borrowAmount, 0, '0x00', deployer.address, 0);

            const usdoBalanceOfDeployer = await usd0.balanceOf(deployer.address);
            expect(usdoBalanceOfDeployer.eq(borrowAmount)).to.be.true;

        })
    });

    describe('sendFrom()', () => {
        it('should test send from', async () => {
            const {
                deployer,
                bar,
                mediumRiskMC,
                yieldBox,
                weth,
                usdc,
                wethAssetId,
                magnetar,
                createWethUsd0Singularity,
                deployCurveStableToUsdoBidder,
            } = await loadFixture(register);

            const {
                singularitySrc,
                singularityDst,
                lzEndpointSrc,
                lzEndpointDst,
                usd0Src,
                usd0Dst,
                usd0DstId,
                usd0SrcId,
            } = await setupUsd0Environment(
                mediumRiskMC,
                yieldBox,
                bar,
                usdc,
                weth,
                wethAssetId,
                createWethUsd0Singularity,
                deployCurveStableToUsdoBidder,
                deployer,
            );
            const adapterParams = ethers.utils.solidityPack(
                ['uint16', 'uint256'],
                [1, 2250000],
            );

            const usdoAmount = ethers.BigNumber.from((1e18).toString()).mul(100);
            await usd0Dst.mint(deployer.address, usdoAmount);

            await usd0Dst.setUseCustomAdapterParams(true);
            await usd0Src.setUseCustomAdapterParams(true);

            await usd0Src.setMinDstGas(await lzEndpointDst.getChainId(), 1, 1);
            await usd0Src.setMinDstGas(await lzEndpointDst.getChainId(), 0, 1);
            await usd0Dst.setMinDstGas(await lzEndpointSrc.getChainId(), 1, 1);
            await usd0Dst.setMinDstGas(await lzEndpointSrc.getChainId(), 0, 1);

            const sendFromEncoded = usd0Dst.interface.encodeFunctionData(
                'sendFrom',
                [
                    deployer.address,
                    1,
                    ethers.utils.defaultAbiCoder.encode(
                        ['address'],
                        [deployer.address],
                    ),
                    usdoAmount,
                    {
                        refundAddress: deployer.address,
                        zroPaymentAddress: ethers.constants.AddressZero,
                        adapterParams,
                    },
                ],
            );
            await usd0Dst.approve(magnetar.address, ethers.constants.MaxUint256);
            await magnetar.connect(deployer).burst(
                [
                    {
                        id: 301,
                        target: usd0Dst.address,
                        value: ethers.utils.parseEther('1'),
                        allowFailure: false,
                        call: sendFromEncoded,
                    },
                ],
                { value: ethers.utils.parseEther('1') },
            );

            const usdoDstBalance = await usd0Dst.balanceOf(deployer.address);
            expect(usdoDstBalance.eq(0)).to.be.true;

            const usdoSrcBalance = await usd0Src.balanceOf(deployer.address);
            expect(usdoSrcBalance.gt(0)).to.be.true;
        });
    });

    describe('permits', () => {
        it('should test an array of permits', async () => {
            const { deployer, eoa1, magnetar } = await loadFixture(register);

            const name = 'Token One';

            const ERC20Mock = new ERC20Mock__factory(deployer);
            const tokenOne = await ERC20Mock.deploy(
                name,
                symbol,
                0,
                18,
                deployer.address,
            );

            const tokenTwo = await ERC20Mock.deploy(
                'TestTokenTwo',
                'TWO',
                0,
                18,
                deployer.address,
            );

            const chainId = await getChainId();
            const value = BN(42).toNumber();
            const nonce = 0;

            const accounts: any = config.networks.hardhat.accounts;
            const index = 0; // first wallet, increment for next wallets
            const deployerWallet = ethers.Wallet.fromMnemonic(
                accounts.mnemonic,
                accounts.path + `/${index}`,
            );
            const data = buildData(
                chainId,
                tokenOne.address,
                await tokenOne.name(),
                deployer.address,
                eoa1.address,
                value,
                nonce,
            );
            const privateKey = Buffer.from(
                deployerWallet.privateKey.substring(2, 66),
                'hex',
            );
            const signature = signTypedMessage(privateKey, { data });
            const { v, r, s } = fromRpcSig(signature);

            const permitEncodedFnData = tokenOne.interface.encodeFunctionData(
                'permit',
                [deployer.address, eoa1.address, value, MAX_DEADLINE, v, r, s],
            );

            await magnetar.connect(deployer).burst([
                {
                    id: 2,
                    target: tokenOne.address,
                    value: 0,
                    allowFailure: false,
                    call: permitEncodedFnData,
                },
            ]);

            const allowance = await tokenOne.allowance(
                deployer.address,
                eoa1.address,
            );
            expect(allowance.eq(value)).to.be.true;

            await expect(
                magnetar.connect(deployer).burst([
                    {
                        id: 2,
                        target: tokenOne.address,
                        value: 0,
                        allowFailure: false,
                        call: permitEncodedFnData,
                    },
                ]),
            ).to.be.reverted;
        });
    });

    describe('ybDeposit()', () => {
        it('should execute YB deposit asset', async () => {
            const { deployer, eoa1, yieldBox, magnetar, createTokenEmptyStrategy } =
                await loadFixture(register);


            const name = 'Token One';

            const ERC20Mock = new ERC20Mock__factory(deployer);
            const tokenOne = await ERC20Mock.deploy(
                name,
                symbol,
                0,
                18,
                deployer.address,
            );
            await tokenOne.deployed();

            const tokenOneStrategy = await createTokenEmptyStrategy(
                deployer,
                yieldBox.address,
                tokenOne.address,
            );

            await yieldBox.registerAsset(
                1,
                tokenOne.address,
                tokenOneStrategy.address,
                0,
            );
            const tokenOneAssetId = await yieldBox.ids(
                1,
                tokenOne.address,
                tokenOneStrategy.address,
                0,
            );

            const chainId = await getChainId();

            const mintVal = 1;
            tokenOne.freeMint(mintVal);

            const mintValShare = await yieldBox.toShare(
                tokenOneAssetId,
                mintVal,
                false,
            );

            const accounts: any = config.networks.hardhat.accounts;
            const deployerWallet = ethers.Wallet.fromMnemonic(
                accounts.mnemonic,
                accounts.path + '/0',
            );

            const privateKey = Buffer.from(
                deployerWallet.privateKey.substring(2, 66),
                'hex',
            );
            const nonce = 0;
            const data = buildData(
                chainId,
                tokenOne.address,
                await tokenOne.name(),
                deployer.address,
                yieldBox.address,
                mintVal,
                nonce,
            );

            const signature = signTypedMessage(privateKey, { data });
            const { v, r, s } = fromRpcSig(signature);

            const permitEncoded = tokenOne.interface.encodeFunctionData('permit', [
                deployer.address,
                yieldBox.address,
                mintVal,
                MAX_DEADLINE,
                v,
                r,
                s,
            ]);

            const permitAllSigData = await getYieldBoxPermitSignature(
                'all',
                deployer,
                yieldBox,
                magnetar.address,
                tokenOneAssetId.toNumber(),
            );
            const permitAllEncoded = yieldBox.interface.encodeFunctionData(
                'permitAll',
                [
                    deployer.address,
                    magnetar.address,
                    MAX_DEADLINE,
                    permitAllSigData.v,
                    permitAllSigData.r,
                    permitAllSigData.s,
                ],
            );

            const depositAssetEncoded = yieldBox.interface.encodeFunctionData(
                'depositAsset',
                [
                    tokenOneAssetId,
                    deployer.address,
                    deployer.address,
                    0,
                    mintValShare,
                ],
            );

            const calls = [
                {
                    id: 2,
                    target: tokenOne.address,
                    value: 0,
                    allowFailure: false,
                    call: permitEncoded,
                },
                {
                    id: 1,
                    target: yieldBox.address,
                    value: 0,
                    allowFailure: false,
                    call: permitAllEncoded,
                },
                {
                    id: 100,
                    target: yieldBox.address,
                    value: 0,
                    allowFailure: false,
                    call: depositAssetEncoded,
                },
            ];

            const magnetarStaticCallData = await magnetar
                .connect(deployer)
                .callStatic.burst(calls);

            await magnetar.connect(deployer).burst(calls);

            const ybBalance = await yieldBox.balanceOf(
                deployer.address,
                tokenOneAssetId,
            );
            expect(ybBalance.gt(0)).to.be.true;

            //test return data
            const depositReturnedData = ethers.utils.defaultAbiCoder.decode(
                ['uint256', 'uint256'],
                magnetarStaticCallData[2].returnData,
            );
            expect(depositReturnedData[0]).to.eq(1);
        });
    });

    describe('lend()', () => {
        it('should lend', async () => {
            const {
                deployer,
                eoa1,
                yieldBox,
                createTokenEmptyStrategy,
                deployCurveStableToUsdoBidder,
                usd0,
                bar,
                __wethUsdcPrice,
                wethUsdcOracle,
                weth,
                wethAssetId,
                mediumRiskMC,
                usdc,
                magnetar,
            } = await loadFixture(register);

            const usdoStratregy = await bar.emptyStrategies(usd0.address);
            const usdoAssetId = await yieldBox.ids(
                1,
                usd0.address,
                usdoStratregy,
                0,
            );

            //Deploy & set Singularity
            const SGLLiquidation = new SGLLiquidation__factory(deployer);
            const _sglLiquidationModule = await SGLLiquidation.deploy();

            const SGLLendingBorrowing = new SGLLendingBorrowing__factory(deployer);
            const _sglLendingBorrowingModule = await SGLLendingBorrowing.deploy();

            const collateralSwapPath = [usd0.address, weth.address];

            const newPrice = __wethUsdcPrice.div(1000000);
            await wethUsdcOracle.set(newPrice);

            const sglData = new ethers.utils.AbiCoder().encode(
                [
                    'address',
                    'address',
                    'address',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                ],
                [
                    _sglLiquidationModule.address,
                    _sglLendingBorrowingModule.address,
                    bar.address,
                    usd0.address,
                    usdoAssetId,
                    weth.address,
                    wethAssetId,
                    wethUsdcOracle.address,
                    ethers.utils.parseEther('1'),
                ],
            );
            await bar.registerSingularity(mediumRiskMC.address, sglData, true);
            const wethUsdoSingularity = new ethers.Contract(
                await bar.clonesOf(
                    mediumRiskMC.address,
                    (await bar.clonesOfCount(mediumRiskMC.address)).sub(1),
                ),
                SingularityArtifact.abi,
                ethers.provider,
            );

            //Deploy & set LiquidationQueue
            await usd0.setMinterStatus(wethUsdoSingularity.address, true);
            await usd0.setBurnerStatus(wethUsdoSingularity.address, true);

            const LiquidationQueue = new LiquidationQueue__factory(deployer);
            const liquidationQueue = await LiquidationQueue.deploy();

            const feeCollector = new ethers.Wallet(
                ethers.Wallet.createRandom().privateKey,
                ethers.provider,
            );

            const { stableToUsdoBidder } = await deployCurveStableToUsdoBidder(
                deployer,
                bar,
                usdc,
                usd0,
            );

            const LQ_META = {
                activationTime: 600, // 10min
                minBidAmount: ethers.BigNumber.from((1e18).toString()).mul(200), // 200 USDC
                closeToMinBidAmount: ethers.BigNumber.from((1e18).toString()).mul(
                    202,
                ),
                defaultBidAmount: ethers.BigNumber.from((1e18).toString()).mul(400), // 400 USDC
                feeCollector: feeCollector.address,
                bidExecutionSwapper: ethers.constants.AddressZero,
                usdoSwapper: stableToUsdoBidder.address,
            };
            await liquidationQueue.init(LQ_META, wethUsdoSingularity.address);

            const payload = wethUsdoSingularity.interface.encodeFunctionData(
                'setLiquidationQueue',
                [liquidationQueue.address],
            );

            await (
                await bar.executeMarketFn(
                    [wethUsdoSingularity.address],
                    [payload],
                    true,
                )
            ).wait();

            const usdoAmount = ethers.BigNumber.from((1e6).toString());
            const usdoShare = await yieldBox.toShare(
                usdoAssetId,
                usdoAmount,
                false,
            );
            await usd0.mint(deployer.address, usdoAmount);

            const chainId = await getChainId();

            const accounts: any = config.networks.hardhat.accounts;
            const deployerWallet = ethers.Wallet.fromMnemonic(
                accounts.mnemonic,
                accounts.path + '/0',
            );

            const privateKey = Buffer.from(
                deployerWallet.privateKey.substring(2, 66),
                'hex',
            );
            const nonce = 0;
            const data = buildData(
                chainId,
                usd0.address,
                await usd0.name(),
                deployer.address,
                yieldBox.address,
                usdoAmount.toNumber(),
                nonce,
            );

            const signature = signTypedMessage(privateKey, { data });
            const { v, r, s } = fromRpcSig(signature);

            const permitEncoded = usd0.interface.encodeFunctionData('permit', [
                deployer.address,
                yieldBox.address,
                usdoAmount,
                MAX_DEADLINE,
                v,
                r,
                s,
            ]);

            let permitAllSigData = await getYieldBoxPermitSignature(
                'all',
                deployer,
                yieldBox,
                magnetar.address,
                usdoAssetId.toNumber(),
            );
            const permitAllEncoded = yieldBox.interface.encodeFunctionData(
                'permitAll',
                [
                    deployer.address,
                    magnetar.address,
                    MAX_DEADLINE,
                    permitAllSigData.v,
                    permitAllSigData.r,
                    permitAllSigData.s,
                ],
            );

            permitAllSigData = await getYieldBoxPermitSignature(
                'all',
                deployer,
                yieldBox,
                wethUsdoSingularity.address,
                usdoAssetId.toNumber(),
                MAX_DEADLINE,
                { nonce: 1 },
            );
            const permitAllSGLEncoded = yieldBox.interface.encodeFunctionData(
                'permitAll',
                [
                    deployer.address,
                    wethUsdoSingularity.address,
                    MAX_DEADLINE,
                    permitAllSigData.v,
                    permitAllSigData.r,
                    permitAllSigData.s,
                ],
            );
            const depositAssetEncoded = yieldBox.interface.encodeFunctionData(
                'depositAsset',
                [usdoAssetId, deployer.address, deployer.address, 0, usdoShare],
            );

            const sglLendEncoded = wethUsdoSingularity.interface.encodeFunctionData(
                'addAsset',
                [deployer.address, deployer.address, false, usdoShare],
            );

            const calls = [
                {
                    id: 2,
                    target: usd0.address,
                    value: 0,
                    allowFailure: false,
                    call: permitEncoded,
                },
                {
                    id: 1,
                    target: yieldBox.address,
                    value: 0,
                    allowFailure: false,
                    call: permitAllEncoded,
                },
                {
                    id: 1,
                    target: yieldBox.address,
                    value: 0,
                    allowFailure: false,
                    call: permitAllSGLEncoded,
                },
                {
                    id: 100,
                    target: yieldBox.address,
                    value: 0,
                    allowFailure: false,
                    call: depositAssetEncoded,
                },
                {
                    id: 203,
                    target: wethUsdoSingularity.address,
                    value: 0,
                    allowFailure: false,
                    call: sglLendEncoded,
                },
            ];

            await magnetar.connect(deployer).burst(calls);

            const ybBalance = await yieldBox.balanceOf(
                deployer.address,
                usdoAssetId,
            );
            expect(ybBalance.eq(0)).to.be.true;

            const sglBalance = await wethUsdoSingularity.balanceOf(
                deployer.address,
            );
            expect(sglBalance.gt(0)).to.be.true;
        });
    });

    describe('add asset', () => {
        it('should deposit and add asset through Magnetar', async () => {
            const {
                yieldBox,
                deployer,
                magnetar,
                registerSingularity,
                mediumRiskMC,
                bar,
            } = await loadFixture(register);

            const TapiocaOFTMock__factory = (
                (await ethers.getContractFactoryFromArtifact(
                    TapiocaOFTArtifact,
                )) as TapiocaOFT__factory
            ).connect(deployer);

            // -------------------  Get LZ endpoints -------------------
            const LZEndpointMock = new LZEndpointMock__factory(deployer);
            const lzEndpoint1 = await LZEndpointMock.deploy(1);
            const lzEndpoint2 = await LZEndpointMock.deploy(2);

            // -------------------   Create TOFT -------------------
            const ERC20Mock = new ERC20Mock__factory(deployer);
            const erc20Mock = await ERC20Mock.deploy(
                'Test',
                'T',
                BN(100e18),
                18,
                deployer.address,
            );
            await erc20Mock.updateMintLimit(BN(100e18));

            // Collateral
            const collateralHost = await TapiocaOFTMock__factory.deploy(
                lzEndpoint1.address,
                false,
                erc20Mock.address,
                yieldBox.address,
                'collateralMock',
                'toftMock',
                18,
                1,
            );

            const collateralLinked = await TapiocaOFTMock__factory.deploy(
                lzEndpoint2.address,
                false,
                erc20Mock.address,
                yieldBox.address,
                'collateralMock',
                'collateralMock',
                18,
                1,
            );

            // Asset
            const USDO = new USDO__factory(deployer);
            const assetHost = await USDO.deploy(
                lzEndpoint1.address,
                yieldBox.address,
                deployer.address,
            );

            const assetLinked = await USDO.deploy(
                lzEndpoint2.address,
                yieldBox.address,
                deployer.address,
            );

            // -------------------  Link TOFTs -------------------

            // Collateral
            lzEndpoint1.setDestLzEndpoint(
                collateralLinked.address,
                lzEndpoint2.address,
            );
            lzEndpoint2.setDestLzEndpoint(
                collateralHost.address,
                lzEndpoint1.address,
            );

            await collateralHost.setTrustedRemote(
                2,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [collateralLinked.address, collateralHost.address],
                ),
            );
            await collateralLinked.setTrustedRemote(
                1,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [collateralHost.address, collateralLinked.address],
                ),
            );
            await collateralHost.setMinDstGas(2, 774, 200_00);
            await collateralHost.setMinDstGas(2, 775, 200_00);
            await collateralLinked.setMinDstGas(1, 774, 200_00);
            await collateralLinked.setMinDstGas(1, 775, 200_00);

            // Asset
            lzEndpoint1.setDestLzEndpoint(assetLinked.address, lzEndpoint2.address);
            lzEndpoint2.setDestLzEndpoint(assetHost.address, lzEndpoint1.address);
            await assetHost.setTrustedRemote(
                2,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [assetLinked.address, assetHost.address],
                ),
            );
            await assetLinked.setTrustedRemote(
                1,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [assetHost.address, assetLinked.address],
                ),
            );

            // ------------------- Deploy TOFT mock oracle -------------------
            const toftUsdcPrice = BN(22e18);
            const OracleMock = new OracleMock__factory(deployer);
            const toftUsdcOracle = await OracleMock.deploy(
                'WETHMOracle',
                'WETHMOracle',
                toftUsdcPrice.toString(),
            );

            // ------------------- Register Penrose Asset -------------------
            // Collateral
            const collateralHostStrategy = await createTokenEmptyStrategy(
                deployer,
                yieldBox.address,
                collateralHost.address,
            );
            await yieldBox.registerAsset(
                1,
                collateralHost.address,
                collateralHostStrategy.address,
                0,
            );

            const collateralHostAssetId = await yieldBox.ids(
                1,
                collateralHost.address,
                collateralHostStrategy.address,
                0,
            );
            // Asset
            const hostAssetStrategy = await createTokenEmptyStrategy(
                deployer,
                yieldBox.address,
                assetHost.address,
            );
            await yieldBox.registerAsset(
                1,
                assetHost.address,
                hostAssetStrategy.address,
                0,
            );
            const assetHostId = await yieldBox.ids(
                1,
                assetHost.address,
                hostAssetStrategy.address,
                0,
            );

            // ------------------- Deploy ToftUSDC medium risk MC clone-------------------
            const { singularityMarket: assetCollateralSingularity } =
                await registerSingularity(
                    deployer,
                    mediumRiskMC.address,
                    yieldBox,
                    bar,
                    assetHost,
                    assetHostId,
                    collateralHost,
                    collateralHostAssetId,
                    toftUsdcOracle,
                    ethers.utils.parseEther('1'),
                    false,
                );
            // ------------------- Init SGL -------------------
            const collateralMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
            const assetMintVal = collateralMintVal.mul(
                toftUsdcPrice.div((1e18).toString()),
            );

            // We get asset
            await assetLinked.freeMint(assetMintVal);
            // ------------------- Permit Setup -------------------
            const deadline = BN(
                (await ethers.provider.getBlock('latest')).timestamp + 10_000,
            );
            const permitLendAmount = ethers.constants.MaxUint256;
            const buildSig = async (nonce?: number) =>
                await getSGLPermitSignature(
                    'Permit',
                    deployer,
                    assetCollateralSingularity,
                    magnetar.address,
                    permitLendAmount,
                    deadline,
                    { nonce },
                );
            const snapshot = await takeSnapshot();

            // Fail without allowFailure
            {
                const permitLend = await buildSig(12); // wrong nonce
                const permitLendStruct: BaseTOFT.IApprovalStruct = {
                    allowFailure: false,
                    deadline,
                    permitBorrow: false,
                    owner: deployer.address,
                    spender: magnetar.address,
                    value: permitLendAmount,
                    r: permitLend.r,
                    s: permitLend.s,
                    v: permitLend.v,
                    target: assetCollateralSingularity.address,
                };

                // ------------------- Actual TOFT test -------------------

                expect(
                    await assetCollateralSingularity.balanceOf(deployer.address),
                ).to.be.equal(0);
                await assetCollateralSingularity.approve(
                    magnetar.address,
                    permitLendAmount,
                );

                await assetLinked.sendToYBAndLend(
                    deployer.address,
                    deployer.address,
                    1,
                    {
                        amount: assetMintVal,
                        marketHelper: magnetar.address,
                        market: assetCollateralSingularity.address,
                    },
                    {
                        extraGasLimit: 1_000_000,
                        strategyDeposit: false,
                        zroPaymentAddress: ethers.constants.AddressZero,
                    },
                    [permitLendStruct],
                    { value: ethers.utils.parseEther('2') },
                );

                expect(
                    await assetCollateralSingularity.balanceOf(deployer.address),
                ).to.be.eq(0);
            }

            await snapshot.restore();
            // Succeed with allowFailure
            {
                const permitLend = await buildSig(12); // wrong nonce
                const permitLendStruct: BaseTOFT.IApprovalStruct = {
                    allowFailure: true,
                    deadline,
                    permitBorrow: false,
                    owner: deployer.address,
                    spender: magnetar.address,
                    value: permitLendAmount,
                    r: permitLend.r,
                    s: permitLend.s,
                    v: permitLend.v,
                    target: assetCollateralSingularity.address,
                };

                // ------------------- Actual TOFT test -------------------

                expect(
                    await assetCollateralSingularity.balanceOf(deployer.address),
                ).to.be.equal(0);

                await assetCollateralSingularity.approve(
                    magnetar.address,
                    permitLendAmount,
                );
                await assetLinked.sendToYBAndLend(
                    deployer.address,
                    deployer.address,
                    1,
                    {
                        amount: assetMintVal,
                        marketHelper: magnetar.address,
                        market: assetCollateralSingularity.address,
                    },
                    {
                        extraGasLimit: 1_000_000,
                        strategyDeposit: false,
                        zroPaymentAddress: ethers.constants.AddressZero,
                    },
                    [permitLendStruct],
                    { value: ethers.utils.parseEther('2') },
                );

                expect(
                    await assetCollateralSingularity.balanceOf(deployer.address),
                ).to.be.eq(
                    await yieldBox.toShare(assetHostId, assetMintVal, false),
                );
            }

            await snapshot.restore();
            // Success with normal flow
            {
                const permitLend = await buildSig(); // wrong nonce
                const permitLendStruct: BaseTOFT.IApprovalStruct = {
                    allowFailure: false,
                    deadline,
                    permitBorrow: false,
                    owner: deployer.address,
                    spender: magnetar.address,
                    value: permitLendAmount,
                    r: permitLend.r,
                    s: permitLend.s,
                    v: permitLend.v,
                    target: assetCollateralSingularity.address,
                };

                // ------------------- Actual TOFT test -------------------

                expect(
                    await assetCollateralSingularity.balanceOf(deployer.address),
                ).to.be.equal(0);

                await assetLinked.sendToYBAndLend(
                    deployer.address,
                    deployer.address,
                    1,
                    {
                        amount: assetMintVal,
                        marketHelper: magnetar.address,
                        market: assetCollateralSingularity.address,
                    },
                    {
                        extraGasLimit: 1_000_000,
                        strategyDeposit: false,
                        zroPaymentAddress: ethers.constants.AddressZero,
                    },
                    [permitLendStruct],
                    { value: ethers.utils.parseEther('2') },
                );

                expect(
                    await assetCollateralSingularity.balanceOf(deployer.address),
                ).to.be.eq(
                    await yieldBox.toShare(assetHostId, assetMintVal, false),
                );
            }
        });

        it('should deposit and add asset through burst', async () => {
            const {
                yieldBox,
                deployer,
                magnetar,
                registerSingularity,
                mediumRiskMC,
                bar,
            } = await loadFixture(register);

            const TapiocaOFTMock__factory = (
                (await ethers.getContractFactoryFromArtifact(
                    TapiocaOFTArtifact,
                )) as TapiocaOFT__factory
            ).connect(deployer);

            // -------------------  Get LZ endpoints -------------------
            const LZEndpointMock = new LZEndpointMock__factory(deployer);
            const lzEndpoint1 = await LZEndpointMock.deploy(1);
            const lzEndpoint2 = await LZEndpointMock.deploy(2);

            // -------------------   Create TOFT -------------------
            const ERC20Mock = new ERC20Mock__factory(deployer);
            const erc20Mock = await ERC20Mock.deploy(
                'Test',
                'T',
                BN(100e18),
                18,
                deployer.address,
            );
            await erc20Mock.updateMintLimit(BN(100e18));

            // Collateral
            const collateralHost = await TapiocaOFTMock__factory.deploy(
                lzEndpoint1.address,
                false,
                erc20Mock.address,
                yieldBox.address,
                'collateralMock',
                'toftMock',
                18,
                1,
            );

            const collateralLinked = await TapiocaOFTMock__factory.deploy(
                lzEndpoint2.address,
                false,
                erc20Mock.address,
                yieldBox.address,
                'collateralMock',
                'collateralMock',
                18,
                1,
            );

            // Asset
            const USDO = new USDO__factory(deployer);
            const assetHost = await USDO.deploy(
                lzEndpoint1.address,
                yieldBox.address,
                deployer.address,
            );

            const assetLinked = await USDO.deploy(
                lzEndpoint2.address,
                yieldBox.address,
                deployer.address,
            );

            // -------------------  Link TOFTs -------------------

            // Collateral
            lzEndpoint1.setDestLzEndpoint(
                collateralLinked.address,
                lzEndpoint2.address,
            );
            lzEndpoint2.setDestLzEndpoint(
                collateralHost.address,
                lzEndpoint1.address,
            );

            await collateralHost.setTrustedRemote(
                2,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [collateralLinked.address, collateralHost.address],
                ),
            );
            await collateralLinked.setTrustedRemote(
                1,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [collateralHost.address, collateralLinked.address],
                ),
            );
            await collateralHost.setMinDstGas(2, 774, 200_00);
            await collateralHost.setMinDstGas(2, 775, 200_00);
            await collateralLinked.setMinDstGas(1, 774, 200_00);
            await collateralLinked.setMinDstGas(1, 775, 200_00);

            // Asset
            lzEndpoint1.setDestLzEndpoint(assetLinked.address, lzEndpoint2.address);
            lzEndpoint2.setDestLzEndpoint(assetHost.address, lzEndpoint1.address);
            await assetHost.setTrustedRemote(
                2,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [assetLinked.address, assetHost.address],
                ),
            );
            await assetLinked.setTrustedRemote(
                1,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [assetHost.address, assetLinked.address],
                ),
            );

            // ------------------- Deploy TOFT mock oracle -------------------
            const toftUsdcPrice = BN(22e18);
            const OracleMock = new OracleMock__factory(deployer);
            const toftUsdcOracle = await OracleMock.deploy(
                'WETHMOracle',
                'WETHMOracle',
                toftUsdcPrice.toString(),
            );

            // ------------------- Register Penrose Asset -------------------
            // Collateral
            const collateralHostStrategy = await createTokenEmptyStrategy(
                deployer,
                yieldBox.address,
                collateralHost.address,
            );
            await yieldBox.registerAsset(
                1,
                collateralHost.address,
                collateralHostStrategy.address,
                0,
            );

            const collateralHostAssetId = await yieldBox.ids(
                1,
                collateralHost.address,
                collateralHostStrategy.address,
                0,
            );
            // Asset
            const hostAssetStrategy = await createTokenEmptyStrategy(
                deployer,
                yieldBox.address,
                assetHost.address,
            );
            await yieldBox.registerAsset(
                1,
                assetHost.address,
                hostAssetStrategy.address,
                0,
            );
            const assetHostId = await yieldBox.ids(
                1,
                assetHost.address,
                hostAssetStrategy.address,
                0,
            );

            // ------------------- Deploy ToftUSDC medium risk MC clone-------------------
            const { singularityMarket: assetCollateralSingularity } =
                await registerSingularity(
                    deployer,
                    mediumRiskMC.address,
                    yieldBox,
                    bar,
                    assetHost,
                    assetHostId,
                    collateralHost,
                    collateralHostAssetId,
                    toftUsdcOracle,
                    ethers.utils.parseEther('1'),
                    false,
                );
            // ------------------- Init SGL -------------------
            const collateralMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
            const assetMintVal = collateralMintVal.mul(
                toftUsdcPrice.div((1e18).toString()),
            );

            // ------------------- Permit Setup -------------------
            const deadline = BN(
                (await ethers.provider.getBlock('latest')).timestamp + 10_000,
            );
            const permitLendAmount = ethers.constants.MaxUint256;
            const permitLend = await getSGLPermitSignature(
                'Permit',
                deployer,
                assetCollateralSingularity,
                magnetar.address,
                permitLendAmount,
                deadline,
            );
            const permitLendStruct: BaseTOFT.IApprovalStruct = {
                allowFailure: false,
                deadline,
                owner: deployer.address,
                spender: magnetar.address,
                value: permitLendAmount,
                r: permitLend.r,
                s: permitLend.s,
                v: permitLend.v,
                target: assetCollateralSingularity.address,
            };

            // ------------------- Actual TOFT test -------------------
            // We get asset
            await assetLinked.freeMint(assetMintVal);

            expect(
                await assetCollateralSingularity.balanceOf(deployer.address),
            ).to.be.equal(0);
            assetCollateralSingularity.approve(magnetar.address, 1);

            const sendToYbAndLendFn = assetLinked.interface.encodeFunctionData(
                'sendToYBAndLend',
                [
                    deployer.address,
                    deployer.address,
                    1,
                    {
                        amount: assetMintVal,
                        marketHelper: magnetar.address,
                        market: assetCollateralSingularity.address,
                    },
                    {
                        extraGasLimit: 1_000_000,
                        strategyDeposit: false,
                        zroPaymentAddress: ethers.constants.AddressZero,
                    },
                    [permitLendStruct],
                ],
            );

            await assetLinked.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );

            await magnetar.connect(deployer).burst(
                [
                    {
                        id: 304,
                        target: assetLinked.address,
                        value: ethers.utils.parseEther('2'),
                        allowFailure: false,
                        call: sendToYbAndLendFn,
                    },
                ],
                {
                    value: ethers.utils.parseEther('2'),
                },
            );

            expect(
                await assetCollateralSingularity.balanceOf(deployer.address),
            ).to.be.eq(await yieldBox.toShare(assetHostId, assetMintVal, false));
        });

        it('Should deposit to yieldBox & add asset', async () => {
            const {
                weth,
                yieldBox,
                wethUsdcSingularity,
                deployer,
                initContracts,
                magnetar,
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const mintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            weth.freeMint(mintVal);

            await weth.approve(magnetar.address, mintVal);
            await magnetar.depositAndAddAsset(
                wethUsdcSingularity.address,
                deployer.address,
                mintVal,
                true,
                true,
            );
        });

        it('Should deposit to yieldBox & add asset to singularity through burst', async () => {
            const {
                weth,
                yieldBox,
                wethUsdcSingularity,
                deployer,
                initContracts,
                magnetar,
                wethAssetId,
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const mintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            weth.freeMint(mintVal);

            await weth.approve(magnetar.address, ethers.constants.MaxUint256);
            const lendFn = magnetar.interface.encodeFunctionData(
                'depositAndAddAsset',
                [
                    wethUsdcSingularity.address,
                    deployer.address,
                    mintVal,
                    true,
                    false,
                ],
            );

            let balanceOfSGL = await wethUsdcSingularity.balanceOf(
                deployer.address,
            );
            expect(balanceOfSGL.gt(0)).to.be.true;

            await magnetar.connect(deployer).burst(
                [
                    {
                        id: 205,
                        target: magnetar.address,
                        value: ethers.utils.parseEther('2'),
                        allowFailure: false,
                        call: lendFn,
                    },
                ],
                {
                    value: ethers.utils.parseEther('2'),
                },
            );

            balanceOfSGL = await wethUsdcSingularity.balanceOf(deployer.address);
            const amount = await yieldBox.toAmount(
                wethAssetId,
                balanceOfSGL,
                false,
            );
            expect(amount.gte(mintVal)).to.be.true;
        });
    })

    describe('add collateral', () => {
        it('should deposit, and borrow through Magnetar', async () => {
            const {
                yieldBox,
                eoa1,
                deployer,
                magnetar,
                registerSingularity,
                mediumRiskMC,
                bar,
            } = await loadFixture(register);

            const TapiocaOFTMock__factory = (
                (await ethers.getContractFactoryFromArtifact(
                    TapiocaOFTArtifact,
                )) as TapiocaOFT__factory
            ).connect(deployer);

            // -------------------  Get LZ endpoints -------------------
            const LZEndpointMock = new LZEndpointMock__factory(deployer);
            const lzEndpoint1 = await LZEndpointMock.deploy(1);
            const lzEndpoint2 = await LZEndpointMock.deploy(2);
            // -------------------   Create TOFT -------------------
            const ERC20Mock = new ERC20Mock__factory(deployer);
            const erc20Mock = await ERC20Mock.deploy(
                'Test',
                'T',
                BN(100e18),
                18,
                deployer.address,
            );
            await erc20Mock.updateMintLimit(BN(100e18));

            // Collateral
            const collateralHost = await TapiocaOFTMock__factory.deploy(
                lzEndpoint1.address,
                false,
                erc20Mock.address,
                yieldBox.address,
                'collateralMock',
                'toftMock',
                18,
                1,
            );

            const collateralLinked = await TapiocaOFTMock__factory.deploy(
                lzEndpoint2.address,
                false,
                erc20Mock.address,
                yieldBox.address,
                'collateralMock',
                'collateralMock',
                18,
                1,
            );

            // Asset
            const USDO = new USDO__factory(deployer);
            const assetHost = await USDO.deploy(
                lzEndpoint1.address,
                yieldBox.address,
                deployer.address,
            );

            const assetLinked = await USDO.deploy(
                lzEndpoint2.address,
                yieldBox.address,
                deployer.address,
            );

            // -------------------  Link TOFTs -------------------

            // Collateral
            lzEndpoint1.setDestLzEndpoint(
                collateralLinked.address,
                lzEndpoint2.address,
            );
            lzEndpoint2.setDestLzEndpoint(
                collateralHost.address,
                lzEndpoint1.address,
            );

            await collateralHost.setTrustedRemote(
                2,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [collateralLinked.address, collateralHost.address],
                ),
            );
            await collateralLinked.setTrustedRemote(
                1,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [collateralHost.address, collateralLinked.address],
                ),
            );
            await collateralHost.setMinDstGas(2, 774, 200_000);
            await collateralHost.setMinDstGas(2, 775, 200_000);
            await collateralLinked.setMinDstGas(1, 774, 200_000);
            await collateralLinked.setMinDstGas(1, 775, 200_000);

            await assetHost.setUseCustomAdapterParams(true);
            await assetLinked.setUseCustomAdapterParams(true);
            await assetHost.setMinDstGas(2, 0, 200_000);
            await assetLinked.setMinDstGas(1, 0, 200_000);

            // Asset
            lzEndpoint1.setDestLzEndpoint(assetLinked.address, lzEndpoint2.address);
            lzEndpoint2.setDestLzEndpoint(assetHost.address, lzEndpoint1.address);
            await assetHost.setTrustedRemote(
                2,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [assetLinked.address, assetHost.address],
                ),
            );
            await assetLinked.setTrustedRemote(
                1,
                ethers.utils.solidityPack(
                    ['address', 'address'],
                    [assetHost.address, assetLinked.address],
                ),
            );

            // ------------------- Deploy TOFT mock oracle -------------------
            const toftUsdcPrice = BN(22e18);
            const OracleMock = new OracleMock__factory(deployer);
            const toftUsdcOracle = await OracleMock.deploy(
                'WETHMOracle',
                'WETHMOracle',
                toftUsdcPrice.toString(),
            );

            // ------------------- Register Penrose Asset -------------------
            // Collateral
            const collateralHostStrategy = await createTokenEmptyStrategy(
                deployer,
                yieldBox.address,
                collateralHost.address,
            );
            await yieldBox.registerAsset(
                1,
                collateralHost.address,
                collateralHostStrategy.address,
                0,
            );

            const collateralHostAssetId = await yieldBox.ids(
                1,
                collateralHost.address,
                collateralHostStrategy.address,
                0,
            );
            // Asset
            const hostAssetStrategy = await createTokenEmptyStrategy(
                deployer,
                yieldBox.address,
                assetHost.address,
            );
            await yieldBox.registerAsset(
                1,
                assetHost.address,
                hostAssetStrategy.address,
                0,
            );
            const assetHostId = await yieldBox.ids(
                1,
                assetHost.address,
                hostAssetStrategy.address,
                0,
            );

            // ------------------- Deploy ToftUSDC medium risk MC clone-------------------
            const { singularityMarket: assetCollateralSingularity } =
                await registerSingularity(
                    deployer,
                    mediumRiskMC.address,
                    yieldBox,
                    bar,
                    assetHost,
                    assetHostId,
                    collateralHost,
                    collateralHostAssetId,
                    toftUsdcOracle,
                    ethers.utils.parseEther('1'),
                    false,
                );
            // ------------------- Init SGL -------------------
            const borrowAmount = ethers.BigNumber.from((1e10).toString());
            const collateralMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
            const assetMintVal = collateralMintVal.mul(
                toftUsdcPrice.div((1e18).toString()),
            );

            // We get asset
            await assetHost.connect(eoa1).freeMint(assetMintVal);

            await assetHost.connect(eoa1).approve(magnetar.address, assetMintVal);
            await magnetar
                .connect(eoa1)
                .depositAndAddAsset(
                    assetCollateralSingularity.address,
                    eoa1.address,
                    assetMintVal,
                    true,
                    true,
                );

            // ------------------- Permit Setup -------------------
            const deadline = BN(
                (await ethers.provider.getBlock('latest')).timestamp + 10_000,
            );
            const permitBorrowAmount = ethers.constants.MaxUint256;
            const permitBorrow = await getSGLPermitSignature(
                'PermitBorrow',
                deployer,
                assetCollateralSingularity,
                magnetar.address,
                permitBorrowAmount,
                deadline,
            );

            const permitBorrowStruct: BaseTOFT.IApprovalStruct = {
                allowFailure: false,
                deadline,
                permitBorrow: true,
                owner: deployer.address,
                spender: magnetar.address,
                value: permitBorrowAmount,
                r: permitBorrow.r,
                s: permitBorrow.s,
                v: permitBorrow.v,
                target: assetCollateralSingularity.address,
            };

            const permitLendAmount = ethers.constants.MaxUint256;
            const permitLend = await getSGLPermitSignature(
                'Permit',
                deployer,
                assetCollateralSingularity,
                magnetar.address,
                permitLendAmount,
                deadline,
                {
                    nonce: (
                        await assetCollateralSingularity.nonces(deployer.address)
                    ).add(1),
                },
            );
            const permitLendStruct: BaseTOFT.IApprovalStruct = {
                allowFailure: false,
                deadline,
                owner: deployer.address,
                permitBorrow: false,
                spender: magnetar.address,
                value: permitLendAmount,
                r: permitLend.r,
                s: permitLend.s,
                v: permitLend.v,
                target: assetCollateralSingularity.address,
            };

            // ------------------- Actual TOFT test -------------------
            // We get asset
            await erc20Mock.freeMint(collateralMintVal);
            await erc20Mock.approve(collateralLinked.address, collateralMintVal);
            await collateralLinked.wrap(
                deployer.address,
                deployer.address,
                collateralMintVal,
            );

            const withdrawFees = await assetHost.estimateSendFee(
                2,
                ethers.utils
                    .solidityPack(['address'], [assetLinked.address])
                    .padEnd(66, '0'),
                borrowAmount,
                false,
                '0x',
            );

            await collateralLinked.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );

            const airdropAdapterParams = ethers.utils.solidityPack(
                ['uint16', 'uint', 'uint', 'address'],
                [
                    2, //it needs to be 2
                    1_500_000, //extra gas limit; min 200k
                    ethers.utils.parseEther('4.678'), //amount of eth to airdrop
                    magnetar.address,
                ],
            );


            const sendToYBAndBorrowFn =
                collateralLinked.interface.encodeFunctionData('sendToYBAndBorrow', [
                    deployer.address,
                    deployer.address,
                    1,
                    airdropAdapterParams,
                    {
                        amount: collateralMintVal,
                        borrowAmount,
                        marketHelper: magnetar.address,
                        market: assetCollateralSingularity.address,
                    },
                    {
                        withdrawAdapterParams: ethers.utils.solidityPack(
                            ['uint16', 'uint256'],
                            [1, 2_250_000],
                        ),
                        withdrawLzChainId: 2,
                        withdrawLzFeeAmount: withdrawFees.nativeFee,
                        withdrawOnOtherChain: true,
                    },
                    {
                        extraGasLimit: 6_000_000,
                        wrap: false,
                        zroPaymentAddress: ethers.constants.AddressZero,
                    },
                    [permitBorrowStruct, permitLendStruct],
                ]);

            await assetLinked.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );
            await magnetar.connect(deployer).burst(
                [
                    {
                        id: 303,
                        target: collateralLinked.address,
                        value: ethers.utils.parseEther('14'),
                        allowFailure: false,
                        call: sendToYBAndBorrowFn,
                    },
                ],
                {
                    value: ethers.utils.parseEther('14'),
                },
            );
            expect(await assetLinked.balanceOf(deployer.address)).to.be.eq(
                borrowAmount,
            );
        });

        it('should deposit, add collateral, borrow and withdraw through burst', async () => {
            const {
                weth,
                deployer,
                wethUsdcSingularity,
                usdc,
                eoa1,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
                yieldBox,
            } = await loadFixture(register);

            const collateralId = await wethUsdcSingularity.collateralId();

            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            const usdcMintVal = wethMintVal
                .mul(10)
                .mul(__wethUsdcPrice.div((1e18).toString()));

            // We get asset
            await weth.freeMint(wethMintVal);
            await usdc.connect(eoa1).freeMint(usdcMintVal);

            // We lend WETH as deployer
            await approveTokensAndSetBarApproval();
            await wethDepositAndAddAsset(wethMintVal);

            await usdc.connect(eoa1).approve(magnetar.address, usdcMintVal);
            await wethUsdcSingularity
                .connect(eoa1)
                .approveBorrow(magnetar.address, ethers.constants.MaxUint256);

            const borrowFn = magnetar.interface.encodeFunctionData(
                'depositAddCollateralAndBorrow',
                [
                    wethUsdcSingularity.address,
                    eoa1.address,
                    usdcMintVal,
                    borrowAmount,
                    true,
                    true,
                    true,
                    encodeMagnetarWithdrawData(false, 0, eoa1.address, '0x00'),
                ],
            );

            let borrowPart = await wethUsdcSingularity.userBorrowPart(eoa1.address);
            expect(borrowPart.eq(0)).to.be.true;
            await magnetar.connect(eoa1).burst(
                [
                    {
                        id: 206,
                        target: magnetar.address,
                        value: ethers.utils.parseEther('2'),
                        allowFailure: false,
                        call: borrowFn,
                    },
                ],
                {
                    value: ethers.utils.parseEther('2'),
                },
            );
            borrowPart = await wethUsdcSingularity.userBorrowPart(eoa1.address);
            expect(borrowPart.gte(borrowAmount)).to.be.true;
        });

        it('should deposit, add collateral and borrow through Magnetar', async () => {
            const {
                weth,
                yieldBox,
                wethUsdcSingularity,
                deployer,
                usdc,
                eoa1,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const assetId = await wethUsdcSingularity.assetId();
            const collateralId = await wethUsdcSingularity.collateralId();

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            const usdcMintVal = wethMintVal
                .mul(10)
                .mul(__wethUsdcPrice.div((1e18).toString()));

            // We get asset
            await weth.freeMint(wethMintVal);
            await usdc.connect(eoa1).freeMint(usdcMintVal);

            // We lend WETH as deployer
            await approveTokensAndSetBarApproval();
            await wethDepositAndAddAsset(wethMintVal);

            await usdc.connect(eoa1).approve(magnetar.address, usdcMintVal);
            await wethUsdcSingularity
                .connect(eoa1)
                .approveBorrow(magnetar.address, ethers.constants.MaxUint256);
            await magnetar
                .connect(eoa1)
                .depositAddCollateralAndBorrow(
                    wethUsdcSingularity.address,
                    eoa1.address,
                    usdcMintVal,
                    borrowAmount,
                    true,
                    true,
                    false,
                    ethers.utils.toUtf8Bytes(''),
                );
        });

        it('should deposit, add collateral, borrow and withdraw through Magnetar', async () => {
            const {
                weth,
                deployer,
                wethUsdcSingularity,
                usdc,
                eoa1,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
                yieldBox,
            } = await loadFixture(register);

            const collateralId = await wethUsdcSingularity.collateralId();

            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            const usdcMintVal = wethMintVal
                .mul(10)
                .mul(__wethUsdcPrice.div((1e18).toString()));

            // We get asset
            await weth.freeMint(wethMintVal);
            await usdc.connect(eoa1).freeMint(usdcMintVal);

            // We lend WETH as deployer
            await approveTokensAndSetBarApproval();
            await wethDepositAndAddAsset(wethMintVal);

            await usdc.connect(eoa1).approve(magnetar.address, usdcMintVal);
            await wethUsdcSingularity
                .connect(eoa1)
                .approveBorrow(magnetar.address, ethers.constants.MaxUint256);

            await magnetar
                .connect(eoa1)
                .depositAddCollateralAndBorrow(
                    wethUsdcSingularity.address,
                    eoa1.address,
                    usdcMintVal,
                    borrowAmount,
                    true,
                    true,
                    true,
                    encodeMagnetarWithdrawData(false, 0, eoa1.address, '0x00'),
                );
        });

        it('should deposit, add collateral, borrow and withdraw through Magnetar without withdraw', async () => {
            const {
                weth,
                deployer,
                wethUsdcSingularity,
                usdc,
                eoa1,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
                yieldBox,
            } = await loadFixture(register);

            const collateralId = await wethUsdcSingularity.collateralId();

            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            const usdcMintVal = wethMintVal
                .mul(10)
                .mul(__wethUsdcPrice.div((1e18).toString()));

            // We get asset
            await weth.freeMint(wethMintVal);
            await usdc.connect(eoa1).freeMint(usdcMintVal);

            // We lend WETH as deployer
            await approveTokensAndSetBarApproval();
            await wethDepositAndAddAsset(wethMintVal);

            await usdc.connect(eoa1).approve(magnetar.address, usdcMintVal);
            await wethUsdcSingularity
                .connect(eoa1)
                .approveBorrow(magnetar.address, ethers.constants.MaxUint256);
            await magnetar
                .connect(eoa1)
                .depositAddCollateralAndBorrow(
                    wethUsdcSingularity.address,
                    eoa1.address,
                    usdcMintVal,
                    borrowAmount,
                    true,
                    true,
                    false,
                    ethers.utils.toUtf8Bytes(''),
                );
        });

        it('should add collateral, borrow and withdraw through Magnetar', async () => {
            const {
                weth,
                deployer,
                wethUsdcSingularity,
                usdc,
                usdcAssetId,
                eoa1,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
                yieldBox,
                usdcDepositAndAddCollateral,
            } = await loadFixture(register);

            const collateralId = await wethUsdcSingularity.collateralId();
            const assetId = await wethUsdcSingularity.assetId();
            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            const usdcMintVal = wethMintVal
                .mul(10)
                .mul(__wethUsdcPrice.div((1e18).toString()));

            // We get asset
            await weth.freeMint(wethMintVal);
            await usdc.connect(eoa1).freeMint(usdcMintVal);

            // We lend WETH as deployer
            await approveTokensAndSetBarApproval();
            await approveTokensAndSetBarApproval(eoa1);
            await wethDepositAndAddAsset(wethMintVal);

            await usdc.connect(eoa1).approve(magnetar.address, usdcMintVal);
            await wethUsdcSingularity
                .connect(eoa1)
                .approve(magnetar.address, ethers.constants.MaxUint256);
            await yieldBox
                .connect(eoa1)
                .depositAsset(
                    usdcAssetId,
                    eoa1.address,
                    eoa1.address,
                    usdcMintVal,
                    0,
                );

            await wethUsdcSingularity
                .connect(eoa1)
                .approveBorrow(magnetar.address, ethers.constants.MaxUint256);
            await magnetar
                .connect(eoa1)
                .depositAddCollateralAndBorrow(
                    wethUsdcSingularity.address,
                    eoa1.address,
                    usdcMintVal,
                    borrowAmount,
                    true,
                    false,
                    true,
                    ethers.utils.defaultAbiCoder.encode(
                        ['bool', 'uint16', 'bytes32', 'bytes'],
                        [
                            false,
                            0,
                            '0x00000000000000000000000022076fba2ea9650a028aa499d0444c4aa9af1bf8',
                            ethers.utils.solidityPack(
                                ['uint16', 'uint256'],
                                [1, 1000000],
                            ),
                        ],
                    ),
                );
        });
    });

    describe('repay', () => {
        it('should deposit and repay through Magnetar', async () => {
            const {
                weth,
                wethUsdcSingularity,
                usdc,
                eoa1,
                deployer,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
                yieldBox,
            } = await loadFixture(register);

            const assetId = await wethUsdcSingularity.assetId();
            const collateralId = await wethUsdcSingularity.collateralId();
            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            const usdcMintVal = wethMintVal
                .mul(10)
                .mul(__wethUsdcPrice.div((1e18).toString()));

            // We get asset
            await weth.freeMint(wethMintVal);
            await usdc.connect(eoa1).freeMint(usdcMintVal);

            // We lend WETH as deployer
            await approveTokensAndSetBarApproval();
            await wethDepositAndAddAsset(wethMintVal);

            await usdc.connect(eoa1).approve(magnetar.address, usdcMintVal);
            await wethUsdcSingularity
                .connect(eoa1)
                .approveBorrow(magnetar.address, ethers.constants.MaxUint256);
            await magnetar
                .connect(eoa1)
                .depositAddCollateralAndBorrow(
                    wethUsdcSingularity.address,
                    eoa1.address,
                    usdcMintVal,
                    borrowAmount,
                    true,
                    true,
                    true,
                    encodeMagnetarWithdrawData(false, 0, eoa1.address, '0x00'),
                );

            const userBorrowPart = await wethUsdcSingularity.userBorrowPart(
                eoa1.address,
            );
            await weth.connect(eoa1).freeMint(userBorrowPart.mul(2));

            await weth
                .connect(eoa1)
                .approve(magnetar.address, userBorrowPart.mul(2));
            await wethUsdcSingularity
                .connect(eoa1)
                .approve(
                    magnetar.address,
                    await yieldBox.toShare(assetId, userBorrowPart.mul(2), true),
                );
            await magnetar
                .connect(eoa1)
                .depositAndRepay(
                    wethUsdcSingularity.address,
                    eoa1.address,
                    userBorrowPart.mul(2),
                    userBorrowPart,
                    true,
                    true,
                );
        });

        it('should deposit, repay, remove collateral and withdraw through Magnetar', async () => {
            const {
                usdcAssetId,
                weth,
                wethUsdcSingularity,
                usdc,
                deployer,
                eoa1,
                initContracts,
                yieldBox,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
            } = await loadFixture(register);

            const collateralId = await wethUsdcSingularity.collateralId();
            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            const usdcMintVal = wethMintVal
                .mul(10)
                .mul(__wethUsdcPrice.div((1e18).toString()));

            // We get asset
            await weth.freeMint(wethMintVal);
            await usdc.connect(eoa1).freeMint(usdcMintVal);

            // We lend WETH as deployer
            await approveTokensAndSetBarApproval();
            await wethDepositAndAddAsset(wethMintVal);

            await usdc.connect(eoa1).approve(magnetar.address, usdcMintVal);
            await wethUsdcSingularity
                .connect(eoa1)
                .approveBorrow(magnetar.address, ethers.constants.MaxUint256);

            await magnetar
                .connect(eoa1)
                .depositAddCollateralAndBorrow(
                    wethUsdcSingularity.address,
                    eoa1.address,
                    usdcMintVal,
                    borrowAmount,
                    true,
                    true,
                    true,
                    encodeMagnetarWithdrawData(false, 0, eoa1.address, '0x00'),
                );

            const userBorrowPart = await wethUsdcSingularity.userBorrowPart(
                eoa1.address,
            );

            const collateralShare = await wethUsdcSingularity.userCollateralShare(
                eoa1.address,
            );
            const collateralAmount = await yieldBox.toAmount(
                usdcAssetId,
                collateralShare,
                false,
            );
            const usdcBalanceBefore = await usdc.balanceOf(eoa1.address);

            await weth.connect(eoa1).freeMint(userBorrowPart.mul(2));

            await weth
                .connect(eoa1)
                .approve(magnetar.address, userBorrowPart.mul(2));

            await wethUsdcSingularity
                .connect(eoa1)
                .approveBorrow(
                    magnetar.address,
                    await yieldBox.toShare(collateralId, collateralAmount, true),
                );

            await magnetar
                .connect(eoa1)
                .depositRepayAndRemoveCollateral(
                    wethUsdcSingularity.address,
                    eoa1.address,
                    userBorrowPart.mul(2),
                    userBorrowPart,
                    collateralAmount,
                    true,
                    true,
                    true,
                );
            const usdcBalanceAfter = await usdc.balanceOf(eoa1.address);
            expect(usdcBalanceAfter.gt(usdcBalanceBefore)).to.be.true;
            expect(usdcBalanceAfter.sub(usdcBalanceBefore).eq(collateralAmount)).to
                .be.true;
        });
    });

    describe('mint & lend', () => {
        it('should mint and lend', async () => {
            const {
                weth,
                createWethUsd0Singularity,
                wethBigBangMarket,
                usd0,
                usdc,
                bar,
                wethAssetId,
                mediumRiskMC,
                deployCurveStableToUsdoBidder,
                initContracts,
                yieldBox,
                magnetar,
                deployer,
            } = await loadFixture(register);

            await initContracts();

            const usdoStratregy = await bar.emptyStrategies(usd0.address);
            const usdoAssetId = await yieldBox.ids(
                1,
                usd0.address,
                usdoStratregy,
                0,
            );

            const { stableToUsdoBidder } = await deployCurveStableToUsdoBidder(
                deployer,
                bar,
                usdc,
                usd0,
                false,
            );
            const { wethUsdoSingularity } = await createWethUsd0Singularity(
                deployer,
                usd0,
                weth,
                bar,
                usdoAssetId,
                wethAssetId,
                mediumRiskMC,
                yieldBox,
                stableToUsdoBidder,
                ethers.utils.parseEther('1'),
                false,
            );

            const borrowAmount = ethers.BigNumber.from((1e18).toString()).mul(100);
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);

            // We get asset
            await weth.freeMint(wethMintVal);

            // Approve tokens
            // await approveTokensAndSetBarApproval();
            await yieldBox.setApprovalForAll(wethUsdoSingularity.address, true);
            await wethBigBangMarket.updateOperator(magnetar.address, true);
            await weth.approve(magnetar.address, wethMintVal);
            await wethUsdoSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );
            await magnetar.mintAndLend(
                wethUsdoSingularity.address,
                wethBigBangMarket.address,
                deployer.address,
                wethMintVal,
                borrowAmount,
                true,
                true,
            );

            const bingBangCollateralShare =
                await wethBigBangMarket.userCollateralShare(deployer.address);
            const bingBangCollateralAmount = await yieldBox.toAmount(
                wethAssetId,
                bingBangCollateralShare,
                false,
            );
            expect(bingBangCollateralAmount.eq(wethMintVal)).to.be.true;

            const bingBangBorrowPart = await wethBigBangMarket.userBorrowPart(
                deployer.address,
            );
            expect(bingBangBorrowPart.gte(borrowAmount)).to.be.true;

            const lentAssetShare = await wethUsdoSingularity.balanceOf(
                deployer.address,
            );
            const lentAssetAmount = await yieldBox.toAmount(
                usdoAssetId,
                lentAssetShare,
                false,
            );
            expect(lentAssetAmount.eq(borrowAmount)).to.be.true;
        });
    });

    describe('remove asset', () => {
        it('should remove asset, repay BingBang, remove collateral and withdraw', async () => {
            const {
                weth,
                createWethUsd0Singularity,
                wethBigBangMarket,
                usd0,
                usdc,
                bar,
                wethAssetId,
                mediumRiskMC,
                deployCurveStableToUsdoBidder,
                initContracts,
                yieldBox,
                magnetar,
                deployer,
            } = await loadFixture(register);

            await initContracts();

            const usdoStratregy = await bar.emptyStrategies(usd0.address);
            const usdoAssetId = await yieldBox.ids(
                1,
                usd0.address,
                usdoStratregy,
                0,
            );

            const { stableToUsdoBidder } = await deployCurveStableToUsdoBidder(
                deployer,
                bar,
                usdc,
                usd0,
                false,
            );
            const { wethUsdoSingularity } = await createWethUsd0Singularity(
                deployer,
                usd0,
                weth,
                bar,
                usdoAssetId,
                wethAssetId,
                mediumRiskMC,
                yieldBox,
                stableToUsdoBidder,
                ethers.utils.parseEther('1'),
                false,
            );

            const borrowAmount = ethers.BigNumber.from((1e18).toString()).mul(100);
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);

            await usd0.mint(deployer.address, borrowAmount.mul(2));
            // We get asset
            await weth.freeMint(wethMintVal);

            // Approve tokens
            // await approveTokensAndSetBarApproval();
            await yieldBox.setApprovalForAll(wethUsdoSingularity.address, true);
            await wethBigBangMarket.updateOperator(magnetar.address, true);
            await weth.approve(magnetar.address, wethMintVal);
            await wethUsdoSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );

            await magnetar.mintAndLend(
                wethUsdoSingularity.address,
                wethBigBangMarket.address,
                deployer.address,
                wethMintVal,
                borrowAmount,
                true,
                true,
            );

            await usd0.approve(yieldBox.address, ethers.constants.MaxUint256);
            await yieldBox.depositAsset(
                usdoAssetId,
                deployer.address,
                deployer.address,
                borrowAmount,
                0,
            );
            const wethBalanceBefore = await weth.balanceOf(deployer.address);
            const fraction = await wethUsdoSingularity.balanceOf(deployer.address);
            const fractionAmount = await yieldBox.toAmount(
                usdoAssetId,
                fraction,
                false,
            );
            const totalBingBangCollateral =
                await wethBigBangMarket.userCollateralShare(deployer.address);

            await expect(
                magnetar.removeAssetAndRepay(
                    wethUsdoSingularity.address,
                    wethBigBangMarket.address,
                    deployer.address,
                    fraction,
                    fraction,
                    totalBingBangCollateral,
                    true,
                    encodeMagnetarWithdrawData(false, 0, deployer.address, '0x00'),
                ),
            ).to.be.revertedWith('SGL: min limit');

            await magnetar.removeAssetAndRepay(
                wethUsdoSingularity.address,
                wethBigBangMarket.address,
                deployer.address,
                fraction.div(2),
                await yieldBox.toAmount(usdoAssetId, fraction.div(3), false),
                totalBingBangCollateral.div(5),
                true,
                encodeMagnetarWithdrawData(false, 0, deployer.address, '0x00'),
            );
            const wethBalanceAfter = await weth.balanceOf(deployer.address);

            expect(wethBalanceBefore.eq(0)).to.be.true;
            expect(wethBalanceAfter.eq(wethMintVal.div(5))).to.be.true;
        });

        it('should remove asset, repay BingBang and remove collateral', async () => {
            const {
                weth,
                createWethUsd0Singularity,
                wethBigBangMarket,
                usd0,
                usdc,
                bar,
                wethAssetId,
                mediumRiskMC,
                deployCurveStableToUsdoBidder,
                initContracts,
                yieldBox,
                magnetar,
                deployer,
            } = await loadFixture(register);

            await initContracts();

            const usdoStratregy = await bar.emptyStrategies(usd0.address);
            const usdoAssetId = await yieldBox.ids(
                1,
                usd0.address,
                usdoStratregy,
                0,
            );
            const { stableToUsdoBidder } = await deployCurveStableToUsdoBidder(
                deployer,
                bar,
                usdc,
                usd0,
                false,
            );
            const { wethUsdoSingularity } = await createWethUsd0Singularity(
                deployer,
                usd0,
                weth,
                bar,
                usdoAssetId,
                wethAssetId,
                mediumRiskMC,
                yieldBox,
                stableToUsdoBidder,
                ethers.utils.parseEther('1'),
                false,
            );

            const borrowAmount = ethers.BigNumber.from((1e18).toString()).mul(100);
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(10);

            await usd0.mint(deployer.address, borrowAmount.mul(2));
            // We get asset
            await weth.freeMint(wethMintVal);

            // Approve tokens
            // await approveTokensAndSetBarApproval();
            await yieldBox.setApprovalForAll(wethUsdoSingularity.address, true);
            await wethBigBangMarket.updateOperator(magnetar.address, true);
            await weth.approve(magnetar.address, wethMintVal);
            await wethUsdoSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );

            await magnetar.mintAndLend(
                wethUsdoSingularity.address,
                wethBigBangMarket.address,
                deployer.address,
                wethMintVal,
                borrowAmount,
                true,
                true,
            );

            await usd0.approve(yieldBox.address, ethers.constants.MaxUint256);
            await yieldBox.depositAsset(
                usdoAssetId,
                deployer.address,
                deployer.address,
                borrowAmount,
                0,
            );
            const wethCollateralBefore =
                await wethBigBangMarket.userCollateralShare(deployer.address);
            const fraction = await wethUsdoSingularity.balanceOf(deployer.address);
            const fractionAmount = await yieldBox.toAmount(
                usdoAssetId,
                fraction,
                false,
            );
            const totalBingBangCollateral =
                await wethBigBangMarket.userCollateralShare(deployer.address);

            await magnetar.removeAssetAndRepay(
                wethUsdoSingularity.address,
                wethBigBangMarket.address,
                deployer.address,
                fraction.div(2),
                await yieldBox.toAmount(usdoAssetId, fraction.div(3), false),
                totalBingBangCollateral.div(5),
                false,
                encodeMagnetarWithdrawData(false, 0, deployer.address, '0x00'),
            );
            const wethCollateralAfter = await wethBigBangMarket.userCollateralShare(
                deployer.address,
            );

            expect(wethCollateralAfter.lt(wethCollateralBefore)).to.be.true;

            const wethBalanceAfter = await weth.balanceOf(deployer.address);
            expect(wethBalanceAfter.eq(0)).to.be.true;
        });
    });

    it.skip('should deposit, add collateral and borrow through Magnetar', async () => {
        const {
            yieldBox,
            deployer,
            eoa1,
            magnetar,
            registerSingularity,
            mediumRiskMC,
            bar,
            timeTravel,
        } = await loadFixture(register);

        const TapiocaOFTMock__factory = (
            (await ethers.getContractFactoryFromArtifact(
                TapiocaOFTArtifact,
            )) as TapiocaOFT__factory
        ).connect(deployer);

        // -------------------  Get LZ endpoints -------------------
        const LZEndpointMock = new LZEndpointMock__factory(deployer);
        const lzEndpoint1 = await LZEndpointMock.deploy(1);
        const lzEndpoint2 = await LZEndpointMock.deploy(2);

        // -------------------   Create TOFT -------------------
        const ERC20Mock = new ERC20Mock__factory(deployer);
        const erc20Mock = await ERC20Mock.deploy(
            'Test',
            'T',
            BN(100e18),
            18,
            deployer.address,
        );
        // await erc20Mock.updateMintLimit(BN(100e18));

        // Collateral
        const collateralHost = await TapiocaOFTMock__factory.deploy(
            lzEndpoint1.address,
            false,
            erc20Mock.address,
            yieldBox.address,
            'collateralMock',
            'toftMock',
            18,
            1,
        );

        const collateralLinked = await TapiocaOFTMock__factory.deploy(
            lzEndpoint2.address,
            false,
            erc20Mock.address,
            yieldBox.address,
            'collateralMock',
            'collateralMock',
            18,
            1,
        );

        // Asset
        const assetHost = await TapiocaOFTMock__factory.deploy(
            lzEndpoint1.address,
            false,
            erc20Mock.address,
            yieldBox.address,
            'assetHost',
            'assetHost',
            18,
            1,
        );

        const assetLinked = await TapiocaOFTMock__factory.deploy(
            lzEndpoint2.address,
            false,
            erc20Mock.address,
            yieldBox.address,
            'assetLinked',
            'assetLinked',
            18,
            1,
        );

        // -------------------  Link TOFTs -------------------

        // Collateral
        lzEndpoint1.setDestLzEndpoint(
            collateralLinked.address,
            lzEndpoint2.address,
        );
        lzEndpoint2.setDestLzEndpoint(
            collateralHost.address,
            lzEndpoint1.address,
        );

        await collateralHost.setTrustedRemote(
            2,
            ethers.utils.solidityPack(
                ['address', 'address'],
                [collateralLinked.address, collateralHost.address],
            ),
        );
        await collateralLinked.setTrustedRemote(
            1,
            ethers.utils.solidityPack(
                ['address', 'address'],
                [collateralHost.address, collateralLinked.address],
            ),
        );
        await collateralHost.setMinDstGas(2, 774, 200_000);
        await collateralHost.setMinDstGas(2, 775, 200_000);
        await collateralLinked.setMinDstGas(1, 774, 200_000);
        await collateralLinked.setMinDstGas(1, 775, 200_000);

        // Asset
        lzEndpoint1.setDestLzEndpoint(assetLinked.address, lzEndpoint2.address);
        lzEndpoint2.setDestLzEndpoint(assetHost.address, lzEndpoint1.address);
        await assetHost.setTrustedRemote(
            2,
            ethers.utils.solidityPack(
                ['address', 'address'],
                [assetLinked.address, assetHost.address],
            ),
        );
        await assetLinked.setTrustedRemote(
            1,
            ethers.utils.solidityPack(
                ['address', 'address'],
                [assetHost.address, assetLinked.address],
            ),
        );

        // ------------------- Deploy TOFT mock oracle -------------------
        const toftUsdcPrice = BN(22e18);
        const OracleMock = new OracleMock__factory(deployer);
        const toftUsdcOracle = await OracleMock.deploy(
            'WETHMOracle',
            'WETHMOracle',
            toftUsdcPrice.toString(),
        );

        // ------------------- Register Penrose Asset -------------------
        // Collateral
        const collateralHostStrategy = await createTokenEmptyStrategy(
            deployer,
            yieldBox.address,
            collateralHost.address,
        );
        await yieldBox.registerAsset(
            1,
            collateralHost.address,
            collateralHostStrategy.address,
            0,
        );

        const collateralHostAssetId = await yieldBox.ids(
            1,
            collateralHost.address,
            collateralHostStrategy.address,
            0,
        );
        // Asset
        const hostAssetStrategy = await createTokenEmptyStrategy(
            deployer,
            yieldBox.address,
            assetHost.address,
        );
        await yieldBox.registerAsset(
            1,
            assetHost.address,
            hostAssetStrategy.address,
            0,
        );
        const assetHostId = await yieldBox.ids(
            1,
            assetHost.address,
            hostAssetStrategy.address,
            0,
        );

        // ------------------- Deploy ToftUSDC medium risk MC clone-------------------
        const { singularityMarket: assetCollateralSingularity } =
            await registerSingularity(
                deployer,
                mediumRiskMC.address,
                yieldBox,
                bar,
                assetHost,
                assetHostId,
                collateralHost,
                collateralHostAssetId,
                toftUsdcOracle,
                ethers.utils.parseEther('1'),
                false,
            );
        // ------------------- Init SGL -------------------

        const borrowAmount = ethers.BigNumber.from((1e10).toString());
        const collateralMintVal = ethers.BigNumber.from((1e18).toString()).mul(
            10,
        );
        const assetMintVal = collateralMintVal.mul(
            toftUsdcPrice.div((1e18).toString()),
        );

        // We get asset
        await timeTravel(86401);
        await erc20Mock.connect(eoa1).freeMint(assetMintVal);
        await timeTravel(86401);
        await erc20Mock.connect(eoa1).approve(assetHost.address, assetMintVal);
        await assetHost
            .connect(eoa1)
            .wrap(eoa1.address, eoa1.address, assetMintVal);

        await assetHost.connect(eoa1).approve(magnetar.address, assetMintVal);
        await magnetar
            .connect(eoa1)
            .depositAndAddAsset(
                assetCollateralSingularity.address,
                eoa1.address,
                assetMintVal,
                true,
                true,
            );

        // ------------------- Permit Setup -------------------
        const deadline = BN(
            (await ethers.provider.getBlock('latest')).timestamp + 10_000,
        );

        const permitBorrowAmount = ethers.constants.MaxUint256;
        const permitBorrow = await getSGLPermitSignature(
            'PermitBorrow',
            deployer,
            assetCollateralSingularity,
            magnetar.address,
            permitBorrowAmount,
            deadline,
        );
        const permitBorrowStruct: BaseTOFT.IApprovalStruct = {
            allowFailure: false,
            deadline,
            permitBorrow: true,
            owner: deployer.address,
            spender: magnetar.address,
            value: permitBorrowAmount,
            r: permitBorrow.r,
            s: permitBorrow.s,
            v: permitBorrow.v,
            target: assetCollateralSingularity.address,
        };

        const permitLendAmount = ethers.constants.MaxUint256;
        const permitLend = await getSGLPermitSignature(
            'Permit',
            deployer,
            assetCollateralSingularity,
            magnetar.address,
            permitLendAmount,
            deadline,
            {
                nonce: (
                    await assetCollateralSingularity.nonces(deployer.address)
                ).add(1),
            },
        );
        const permitLendStruct: BaseTOFT.IApprovalStruct = {
            allowFailure: false,
            deadline,
            permitBorrow: false,
            owner: deployer.address,
            spender: magnetar.address,
            value: permitLendAmount,
            r: permitLend.r,
            s: permitLend.s,
            v: permitLend.v,
            target: assetCollateralSingularity.address,
        };

        // ------------------- Actual TOFT test -------------------
        const withdrawFees = await assetHost.estimateSendFee(
            2,
            ethers.utils
                .solidityPack(['address'], [assetLinked.address])
                .padEnd(66, '0'),
            borrowAmount,
            false,
            '0x',
        );

        const airdropAdapterParams = ethers.utils.solidityPack(
            ['uint16', 'uint', 'uint', 'address'],
            [
                2, //it needs to be 2
                1_000_000, //extra gas limit; min 200k
                ethers.utils.parseEther('4.678'), //amount of eth to airdrop
                magnetar.address,
            ],
        );

        // Execute
        await timeTravel(86401);
        await erc20Mock.freeMint(collateralMintVal);
        await erc20Mock.approve(collateralLinked.address, collateralMintVal);
        await collateralLinked.wrap(
            deployer.address,
            deployer.address,
            collateralMintVal,
        );

        await collateralLinked.sendToYBAndBorrow(
            deployer.address,
            deployer.address,
            1,
            airdropAdapterParams,
            {
                amount: collateralMintVal,
                borrowAmount,
                marketHelper: magnetar.address,
                market: assetCollateralSingularity.address,
            },
            {
                withdrawAdapterParams: ethers.utils.solidityPack(
                    ['uint16', 'uint256'],
                    [1, 2250000],
                ),
                withdrawLzChainId: 2,
                withdrawLzFeeAmount: withdrawFees.nativeFee,
                withdrawOnOtherChain: true,
            },
            {
                extraGasLimit: 1_000_000,
                strategyDeposit: false,
                wrap: false,
                zroPaymentAddress: ethers.constants.AddressZero,
            },
            [permitBorrowStruct, permitLendStruct],
            { value: ethers.utils.parseEther('15') },
        );
        expect(await assetLinked.balanceOf(deployer.address)).to.be.eq(
            borrowAmount,
        );
    });

});

async function getYieldBoxPermitSignature(
    permitType: 'asset' | 'all',
    wallet: SignerWithAddress,
    token: YieldBox,
    spender: string,
    assetId: number,
    deadline = MAX_DEADLINE,
    permitConfig?: {
        nonce?: any;
        name?: string;
        chainId?: number;
        version?: string;
    },
) {
    const [nonce, name, version, chainId] = await Promise.all([
        permitConfig?.nonce ?? token.nonces(wallet.address),
        'YieldBox',
        permitConfig?.version ?? '1',
        permitConfig?.chainId ?? wallet.getChainId(),
    ]);

    const typesInfo = [
        {
            name: 'owner',
            type: 'address',
        },
        {
            name: 'spender',
            type: 'address',
        },
        {
            name: 'assetId',
            type: 'uint256',
        },
        {
            name: 'nonce',
            type: 'uint256',
        },
        {
            name: 'deadline',
            type: 'uint256',
        },
    ];

    return ethers.utils.splitSignature(
        await wallet._signTypedData(
            {
                name,
                version,
                chainId,
                verifyingContract: token.address,
            },
            permitType === 'asset'
                ? {
                    Permit: typesInfo,
                }
                : {
                    PermitAll: typesInfo.filter(
                        (x) =>
                            permitType !== 'all' ||
                            (permitType === 'all' && x.name !== 'assetId'),
                    ),
                },

            {
                ...(permitType === 'all' ? {} : { assetId }),
                owner: wallet.address,
                spender,
                assetId,
                nonce,
                deadline,
            },
        ),
    );
}

const buildData = (
    chainId: number,
    verifyingContract: string,
    name: string,
    owner: string,
    spender: string,
    value: number,
    nonce: number,
    deadline = MAX_DEADLINE,
) => ({
    primaryType: 'Permit',
    types: { EIP712Domain, Permit },
    domain: { name, version, chainId, verifyingContract },
    message: { owner, spender, value, nonce, deadline },
});


const EIP712Domain = [
    { name: 'name', type: 'string' },
    { name: 'version', type: 'string' },
    { name: 'chainId', type: 'uint256' },
    { name: 'verifyingContract', type: 'address' },
];

const Permit = [
    { name: 'owner', type: 'address' },
    { name: 'spender', type: 'address' },
    { name: 'value', type: 'uint256' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' },
];

const PermitAll = [
    { name: 'owner', type: 'address' },
    { name: 'spender', type: 'address' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' },
];

function encodeMagnetarWithdrawData(
    otherChain: boolean,
    destChain: number,
    receiver: string,
    adapterParams: string,
) {
    const receiverSplit = receiver.split('0x');

    return ethers.utils.defaultAbiCoder.encode(
        ['bool', 'uint16', 'bytes32', 'bytes'],
        [
            otherChain,
            destChain,
            '0x'.concat(receiverSplit[1].padStart(64, '0')),
            adapterParams,
        ],
    );
}

async function getChainId(): Promise<number> {
    const chainIdHex = await hre.network.provider.send('eth_chainId', []);
    return BN(chainIdHex).toNumber();
}

async function setupUsd0Environment(
    mediumRiskMC: any,
    yieldBox: any,
    bar: any,
    usdc: any,
    collateral: any,
    collateralId: any,
    registerSingularity: any,
    registerBidder: any,
    deployer: any,
) {
    //omnichain configuration
    const chainIdSrc = 1;
    const chainIdDst = (await ethers.provider.getNetwork()).chainId;

    const LZEndpointMock = (
        (await ethers.getContractFactoryFromArtifact(
            LZEndpointMockArtifact,
        )) as LZEndpointMock__factory
    ).connect(deployer);

    const lzEndpointSrc = await LZEndpointMock.deploy(chainIdSrc);
    const lzEndpointDst = await LZEndpointMock.deploy(chainIdDst);

    //deploy usd0 tokens
    const USDO = new USDO__factory(deployer);
    const usd0Src = await USDO.deploy(
        lzEndpointSrc.address,
        yieldBox.address,
        deployer.address,
    );

    const usd0SrcStrategy = await createTokenEmptyStrategy(
        deployer,
        yieldBox.address,
        usd0Src.address,
    );
    await yieldBox.registerAsset(
        1,
        usd0Src.address,
        usd0SrcStrategy.address,
        0,
    );
    const usd0SrcId = await yieldBox.ids(
        1,
        usd0Src.address,
        usd0SrcStrategy.address,
        0,
    );

    const usd0Dst = await USDO.deploy(
        lzEndpointDst.address,
        yieldBox.address,
        deployer.address,
    );

    const usd0DstStrategy = await createTokenEmptyStrategy(
        deployer,
        yieldBox.address,
        usd0Dst.address,
    );
    await yieldBox.registerAsset(
        1,
        usd0Dst.address,
        usd0DstStrategy.address,
        0,
    );
    const usd0DstId = await yieldBox.ids(
        1,
        usd0Dst.address,
        usd0DstStrategy.address,
        0,
    );

    //configure trusted remotes for USDO
    await lzEndpointSrc.setDestLzEndpoint(
        usd0Dst.address,
        lzEndpointDst.address,
    );
    await lzEndpointDst.setDestLzEndpoint(
        usd0Src.address,
        lzEndpointSrc.address,
    );

    const dstPath = ethers.utils.solidityPack(
        ['address', 'address'],
        [usd0Dst.address, usd0Src.address],
    );
    const srcPath = ethers.utils.solidityPack(
        ['address', 'address'],
        [usd0Src.address, usd0Dst.address],
    );
    await usd0Src.setTrustedRemote(chainIdDst, dstPath);
    await usd0Dst.setTrustedRemote(chainIdSrc, srcPath);

    //deploy bidders
    const stableToUsdoBidderSrcInfo = await registerBidder(
        deployer,
        bar,
        usdc,
        usd0Src,
        false,
    );
    const stableToUsdoBidderSrc = stableToUsdoBidderSrcInfo.stableToUsdoBidder;

    const stableToUsdoBidderDstInfo = await registerBidder(
        deployer,
        bar,
        usdc,
        usd0Dst,
        false,
    );
    const stableToUsdoBidderDst = stableToUsdoBidderDstInfo.stableToUsdoBidder;

    //deploy singularities
    const srcSingularityDeployments = await registerSingularity(
        deployer,
        usd0Src,
        collateral,
        bar,
        usd0SrcId,
        collateralId,
        mediumRiskMC,
        yieldBox,
        stableToUsdoBidderSrc,
        ethers.utils.parseEther('1'),
        false,
    );
    const singularitySrc =
        srcSingularityDeployments.wethUsdoSingularity as Singularity;

    const dstSingularityDeployments = await registerSingularity(
        deployer,
        usd0Dst,
        collateral,
        bar,
        usd0DstId,
        collateralId,
        mediumRiskMC,
        yieldBox,
        stableToUsdoBidderDst,
        ethers.utils.parseEther('1'),
        false,
    );
    const singularityDst =
        dstSingularityDeployments.wethUsdoSingularity as Singularity;

    return {
        singularitySrc,
        singularityDst,
        lzEndpointSrc,
        lzEndpointDst,
        usd0Src,
        usd0Dst,
        usd0SrcId,
        usd0DstId,
    };
}

export async function createTokenEmptyStrategy(
    deployer: any,
    yieldBox: string,
    token: string,
) {
    const ERC20WithoutStrategy = new ERC20WithoutStrategy__factory(deployer);
    const noStrategy = await ERC20WithoutStrategy.deploy(yieldBox, token);
    await noStrategy.deployed();
    return noStrategy;
}
