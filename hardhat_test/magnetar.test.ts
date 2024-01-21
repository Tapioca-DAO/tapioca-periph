import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { signTypedMessage } from 'eth-sig-util';
import { fromRpcSig } from 'ethereumjs-utils';
import hre, { config, ethers } from 'hardhat';
import { BN, getSGLPermitSignature, register } from './test.utils';

import SingularityArtifact from '@tapioca-sdk/artifacts/tapioca-bar/Singularity.json';
import LZEndpointMockArtifact from '@tapioca-sdk/artifacts/tapioca-mocks/LZEndpointMock.json';
import TapiocaOFTArtifact from '@tapioca-sdk/artifacts/tapiocaz/TapiocaOFT.json';

import {
    SGLBorrow__factory,
    SGLCollateral__factory,
    SGLLeverage__factory,
    SGLLiquidation__factory,
    Singularity,
    USDOGenericModule__factory,
    USDOLeverageDestinationModule__factory,
    USDOLeverageModule__factory,
    USDOMarketDestinationModule__factory,
    USDOMarketModule__factory,
    USDOOptionsDestinationModule__factory,
    USDOOptionsModule__factory,
    USDO__factory,
} from '@tapioca-sdk/typechain/Tapioca-bar';
import {
    ERC20WithoutStrategy__factory,
    YieldBox,
} from '@tapioca-sdk/typechain/YieldBox';
import {
    ERC20Mock__factory,
    LZEndpointMock__factory,
    OracleMock__factory,
} from '@tapioca-sdk/typechain/tapioca-mocks';
import { TapiocaOFT__factory } from '@tapioca-sdk/typechain/tapiocaz';
import { MagnetarV2 } from '@typechain/index';

const MAX_DEADLINE = 9999999999999;

const symbol = 'MTKN';
const version = '1';

describe.only('MagnetarV2', () => {
    describe('view', () => {
        it('should test sgl info', async () => {
            const {
                deployer,
                yieldBox,
                usd0,
                bar,
                __wethUsdcPrice,
                wethUsdcOracle,
                weth,
                wethAssetId,
                mediumRiskMC,
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

            const SGLCollateral = new SGLCollateral__factory(deployer);
            const _sglCollateralModule = await SGLCollateral.deploy();

            const SGLBorrow = new SGLBorrow__factory(deployer);
            const _sglBorrowModule = await SGLBorrow.deploy();

            const SGLLeverage = new SGLLeverage__factory(deployer);
            const _sglLeverageModule = await SGLLeverage.deploy();

            const newPrice = __wethUsdcPrice.div(1000000);
            await wethUsdcOracle.set(newPrice);

            const sglData = new ethers.utils.AbiCoder().encode(
                [
                    'address',
                    'address',
                    'address',
                    'address',
                    'address',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                    'uint256',
                    'uint256',
                    'address',
                ],
                [
                    _sglLiquidationModule.address,
                    _sglBorrowModule.address,
                    _sglCollateralModule.address,
                    _sglLeverageModule.address,
                    bar.address,
                    usd0.address,
                    usdoAssetId,
                    weth.address,
                    wethAssetId,
                    wethUsdcOracle.address,
                    ethers.utils.parseEther('1'),
                    0,
                    0,
                    ethers.constants.AddressZero,
                ],
            );
            await bar.registerSingularity(mediumRiskMC.address, sglData, true);
        });
    });
    describe('withdrawTo()', () => {
        it('should test withdrawTo', async () => {
            const {
                deployer,
                yieldBox,
                usd0,
                bar,
                __wethUsdcPrice,
                wethUsdcOracle,
                weth,
                wethAssetId,
                mediumRiskMC,
                magnetar,
                timeTravel,
                cluster,
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

            const SGLCollateral = new SGLCollateral__factory(deployer);
            const _sglCollateralModule = await SGLCollateral.deploy();

            const SGLBorrow = new SGLBorrow__factory(deployer);
            const _sglBorrowModule = await SGLBorrow.deploy();

            const SGLLeverage = new SGLLeverage__factory(deployer);
            const _sglLeverageModule = await SGLLeverage.deploy();

            const newPrice = __wethUsdcPrice.div(1000000);
            await wethUsdcOracle.set(newPrice);

            const sglData = new ethers.utils.AbiCoder().encode(
                [
                    'address',
                    'address',
                    'address',
                    'address',
                    'address',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                    'uint256',
                    'uint256',
                    'address',
                ],
                [
                    _sglLiquidationModule.address,
                    _sglBorrowModule.address,
                    _sglCollateralModule.address,
                    _sglLeverageModule.address,
                    bar.address,
                    usd0.address,
                    usdoAssetId,
                    weth.address,
                    wethAssetId,
                    wethUsdcOracle.address,
                    ethers.utils.parseEther('1'),
                    0,
                    0,
                    ethers.constants.AddressZero,
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
            ).connect(deployer);
            await cluster.updateContract(0, wethUsdoSingularity.address, true);

            //Deploy & set LiquidationQueue
            await usd0.setMinterStatus(wethUsdoSingularity.address, true);
            await usd0.setBurnerStatus(wethUsdoSingularity.address, true);

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

            const sglLendEncoded =
                wethUsdoSingularity.interface.encodeFunctionData('addAsset', [
                    deployer.address,
                    deployer.address,
                    false,
                    usdoShare,
                ]);

            await usd0.approve(magnetar.address, ethers.constants.MaxUint256);
            await usd0.approve(yieldBox.address, ethers.constants.MaxUint256);
            await usd0.approve(
                wethUsdoSingularity.address,
                ethers.constants.MaxUint256,
            );
            await yieldBox.setApprovalForAll(deployer.address, true);
            await yieldBox.setApprovalForAll(wethUsdoSingularity.address, true);
            await yieldBox.setApprovalForAll(magnetar.address, true);
            await weth.approve(yieldBox.address, ethers.constants.MaxUint256);
            await weth.approve(magnetar.address, ethers.constants.MaxUint256);
            await wethUsdoSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );
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

            const depositAddCollateralAndBorrowFromMarketData: Parameters<
                MagnetarV2['depositAddCollateralAndBorrowFromMarket']
            > = [
                {
                    market: wethUsdoSingularity.address,
                    user: deployer.address,
                    collateralAmount: wethMintVal,
                    borrowAmount: borrowAmount,
                    extractFromSender: true,
                    deposit: true,
                    withdrawParams: {
                        withdraw: false,
                        withdrawLzFeeAmount: 0,
                        withdrawOnOtherChain: false,
                        withdrawLzChainId: 0,
                        withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                        refundAddress: deployer.address,
                        unwrap: false,
                        zroPaymentAddress: ethers.constants.AddressZero,
                    },
                    valueAmount: 0,
                },
            ];

            const borrowFn = magnetar.interface.encodeFunctionData(
                'depositAddCollateralAndBorrowFromMarket',
                depositAddCollateralAndBorrowFromMarketData,
            );

            let borrowPart = await wethUsdoSingularity.userBorrowPart(
                deployer.address,
            );
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

            const collateralBalance =
                await wethUsdoSingularity.userCollateralShare(deployer.address);
            const collateralAmpunt = await yieldBox.toAmount(
                wethAssetId,
                collateralBalance,
                false,
            );
            expect(collateralAmpunt.eq(wethMintVal)).to.be.true;

            await wethUsdoSingularity
                .connect(deployer)
                .borrow(deployer.address, deployer.address, borrowAmount);

            borrowPart = await wethUsdoSingularity.userBorrowPart(
                deployer.address,
            );
            expect(borrowPart.gte(borrowAmount)).to.be.true;

            const receiverSplit = deployer.address.split('0x');
            await magnetar.withdrawToChain({
                yieldBox: yieldBox.address,
                from: deployer.address,
                assetId: usdoAssetId,
                dstChainId: 0,
                receiver: '0x'.concat(receiverSplit[1].padStart(64, '0')), // address to bytes32
                amount: borrowAmount,
                adapterParams: '0x',
                refundAddress: deployer.address,
                gas: 0,
                unwrap: false,
                zroPaymentAddress: ethers.constants.AddressZero,
            });

            const usdoBalanceOfDeployer = await usd0.balanceOf(
                deployer.address,
            );
            expect(usdoBalanceOfDeployer.eq(borrowAmount)).to.be.true;
        });
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
                cluster,
            } = await loadFixture(register);

            const { lzEndpointSrc, lzEndpointDst, usd0Src, usd0Dst } =
                await setupUsd0Environment(
                    mediumRiskMC,
                    yieldBox,
                    cluster.address,
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

            const usdoAmount = ethers.BigNumber.from((1e18).toString()).mul(10);
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
            await usd0Dst.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );

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
            const { deployer, yieldBox, magnetar, createTokenEmptyStrategy } =
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

            const permitEncoded = tokenOne.interface.encodeFunctionData(
                'permit',
                [
                    deployer.address,
                    yieldBox.address,
                    mintVal,
                    MAX_DEADLINE,
                    v,
                    r,
                    s,
                ],
            );

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
                yieldBox,
                usd0,
                bar,
                __wethUsdcPrice,
                wethUsdcOracle,
                weth,
                wethAssetId,
                mediumRiskMC,
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

            const SGLCollateral = new SGLCollateral__factory(deployer);
            const _sglCollateralModule = await SGLCollateral.deploy();

            const SGLBorrow = new SGLBorrow__factory(deployer);
            const _sglBorrowModule = await SGLBorrow.deploy();

            const SGLLeverage = new SGLLeverage__factory(deployer);
            const _sglLeverageModule = await SGLLeverage.deploy();

            const newPrice = __wethUsdcPrice.div(1000000);
            await wethUsdcOracle.set(newPrice);

            const sglData = new ethers.utils.AbiCoder().encode(
                [
                    'address',
                    'address',
                    'address',
                    'address',
                    'address',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                    'address',
                    'uint256',
                    'uint256',
                    'uint256',
                    'address',
                ],
                [
                    _sglLiquidationModule.address,
                    _sglBorrowModule.address,
                    _sglCollateralModule.address,
                    _sglLeverageModule.address,
                    bar.address,
                    usd0.address,
                    usdoAssetId,
                    weth.address,
                    wethAssetId,
                    wethUsdcOracle.address,
                    ethers.utils.parseEther('1'),
                    0,
                    0,
                    ethers.constants.AddressZero,
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
            ).connect(deployer);

            //Deploy & set LiquidationQueue
            await usd0.setMinterStatus(wethUsdoSingularity.address, true);
            await usd0.setBurnerStatus(wethUsdoSingularity.address, true);

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

            const sglLendEncoded =
                wethUsdoSingularity.interface.encodeFunctionData('addAsset', [
                    deployer.address,
                    deployer.address,
                    false,
                    usdoShare,
                ]);

            await wethUsdoSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
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
        it('Should deposit to yieldBox & add asset', async () => {
            const {
                weth,
                wethUsdcSingularity,
                deployer,
                initContracts,
                magnetar,
                cluster,
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const mintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            weth.freeMint(mintVal);

            await weth.approve(magnetar.address, mintVal);
            await wethUsdcSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );
            await cluster.updateContract(0, wethUsdcSingularity.address, true);
            await magnetar.mintFromBBAndLendOnSGL({
                user: deployer.address,
                lendAmount: mintVal,
                mintData: {
                    mint: false,
                    mintAmount: 0,
                    collateralDepositData: {
                        deposit: false,
                        amount: 0,
                        extractFromSender: false,
                    },
                },
                depositData: {
                    deposit: true,
                    amount: mintVal,
                    extractFromSender: true,
                },
                lockData: {
                    lock: false,
                    amount: 0,
                    lockDuration: 0,
                    target: ethers.constants.AddressZero,
                    fraction: 0,
                },
                participateData: {
                    participate: false,
                    target: ethers.constants.AddressZero,
                    tOLPTokenId: 0,
                },
                externalContracts: {
                    singularity: wethUsdcSingularity.address,
                    magnetar: magnetar.address,
                    bigBang: ethers.constants.AddressZero,
                },
            });
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
                cluster,
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const mintVal = ethers.BigNumber.from((1e18).toString()).mul(10);
            weth.freeMint(mintVal);

            await weth.approve(magnetar.address, ethers.constants.MaxUint256);
            await wethUsdcSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );
            await cluster.updateContract(0, wethUsdcSingularity.address, true);
            const lendFn = magnetar.interface.encodeFunctionData(
                'mintFromBBAndLendOnSGL',
                [
                    {
                        user: deployer.address,
                        lendAmount: mintVal,
                        mintData: {
                            mint: false,
                            mintAmount: 0,
                            collateralDepositData: {
                                deposit: false,
                                amount: 0,
                                extractFromSender: false,
                            },
                        },
                        depositData: {
                            deposit: true,
                            amount: mintVal,
                            extractFromSender: true,
                        },
                        lockData: {
                            lock: false,
                            amount: 0,
                            lockDuration: 0,
                            target: ethers.constants.AddressZero,
                            fraction: 0,
                        },
                        participateData: {
                            participate: false,
                            target: ethers.constants.AddressZero,
                            tOLPTokenId: 0,
                        },
                        externalContracts: {
                            singularity: wethUsdcSingularity.address,
                            magnetar: magnetar.address,
                            bigBang: ethers.constants.AddressZero,
                        },
                    },
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

            balanceOfSGL = await wethUsdcSingularity.balanceOf(
                deployer.address,
            );
            const amount = await yieldBox.toAmount(
                wethAssetId,
                balanceOfSGL,
                false,
            );
            expect(amount.gte(mintVal)).to.be.true;
        });
    });

    describe('add collateral', () => {
        //skipped until BB is added bc .freeMint does not exist anymore
        it.skip('should deposit, and borrow through Magnetar', async () => {
            const {
                yieldBox,
                eoa1,
                deployer,
                magnetar,
                registerSingularity,
                mediumRiskMC,
                cluster,
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
                cluster.address,
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
                cluster.address,
                'collateralMock',
                'collateralMock',
                18,
                1,
            );

            // Asset
            const USDOLeverageModule = new USDOLeverageModule__factory(owner);
            const USDOMarketModule = new USDOMarketModule__factory(owner);

            const usdo_leverage_host = await USDOLeverageModule.deploy(
                lzEndpoint1.address,
                yieldBox.address,
                cluster.address,
            );
            const usdo_market_host = await USDOMarketModule.deploy(
                lzEndpoint1.address,
                yieldBox.address,
                cluster.address,
            );

            const USDO = new USDO__factory(deployer);
            const assetHost = await USDO.deploy(
                lzEndpoint1.address,
                yieldBox.address,
                deployer.address,
                usdo_leverage_host.address,
                usdo_market_host.address,
            );

            const usdo_leverage_linked = await USDOLeverageModule.deploy(
                lzEndpoint2.address,
                yieldBox,
            );
            const usdo_market_linked = await USDOMarketModule.deploy(
                lzEndpoint2.address,
                yieldBox,
            );

            const assetLinked = await USDO.deploy(
                lzEndpoint2.address,
                yieldBox.address,
                deployer.address,
                usdo_leverage_linked.address,
                usdo_market_linked.address,
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
            lzEndpoint1.setDestLzEndpoint(
                assetLinked.address,
                lzEndpoint2.address,
            );
            lzEndpoint2.setDestLzEndpoint(
                assetHost.address,
                lzEndpoint1.address,
            );
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
            const collateralMintVal = ethers.BigNumber.from(
                (1e18).toString(),
            ).mul(10);
            const assetMintVal = collateralMintVal.mul(
                toftUsdcPrice.div((1e18).toString()),
            );

            // We get asset
            await assetHost.connect(eoa1).freeMint(assetMintVal);

            await assetHost
                .connect(eoa1)
                .approve(magnetar.address, assetMintVal);
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
                        await assetCollateralSingularity.nonces(
                            deployer.address,
                        )
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
            await erc20Mock.approve(
                collateralLinked.address,
                collateralMintVal,
            );
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
                collateralLinked.interface.encodeFunctionData(
                    'sendToYBAndBorrow',
                    [
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
                    ],
                );

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
                wethUsdcSingularity,
                usdc,
                eoa1,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
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
                'depositAddCollateralAndBorrowFromMarket',
                [
                    {
                        market: wethUsdcSingularity.address,
                        user: eoa1.address,
                        collateralAmount: usdcMintVal,
                        borrowAmount: borrowAmount,
                        extractFromSender: true,
                        deposit: true,
                        withdrawParams: {
                            withdraw: true,
                            withdrawLzFeeAmount: 0,
                            withdrawOnOtherChain: false,
                            withdrawLzChainId: 0,
                            withdrawAdapterParams: '0x',
                            unwrap: false,
                            refundAddress: eoa1.address,
                            zroPaymentAddress: hre.ethers.constants.AddressZero,
                        },
                        valueAmount: 0,
                    },
                ],
            );
            let borrowPart = await wethUsdcSingularity.userBorrowPart(
                eoa1.address,
            );
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
                wethUsdcSingularity,
                usdc,
                eoa1,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
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
                .depositAddCollateralAndBorrowFromMarket({
                    market: wethUsdcSingularity.address,
                    user: eoa1.address,
                    collateralAmount: usdcMintVal,
                    borrowAmount: borrowAmount,
                    extractFromSender: true,
                    deposit: true,
                    withdrawParams: {
                        withdraw: false,
                        withdrawLzFeeAmount: 0,
                        withdrawOnOtherChain: false,
                        withdrawLzChainId: 0,
                        withdrawAdapterParams: '0x',
                        unwrap: false,
                        refundAddress: eoa1.address,
                        zroPaymentAddress: hre.ethers.constants.AddressZero,
                    },
                    valueAmount: 0,
                });
        });

        it('should deposit, add collateral, borrow and withdraw through Magnetar', async () => {
            const {
                weth,
                wethUsdcSingularity,
                usdc,
                eoa1,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
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
                .depositAddCollateralAndBorrowFromMarket({
                    market: wethUsdcSingularity.address,
                    user: eoa1.address,
                    collateralAmount: usdcMintVal,
                    borrowAmount: borrowAmount,
                    extractFromSender: true,
                    deposit: true,
                    withdrawParams: {
                        withdraw: true,
                        withdrawLzFeeAmount: 0,
                        withdrawOnOtherChain: false,
                        withdrawLzChainId: 0,
                        withdrawAdapterParams: '0x',
                        unwrap: false,
                        refundAddress: eoa1.address,
                        zroPaymentAddress: hre.ethers.constants.AddressZero,
                    },
                    valueAmount: 0,
                });
        });

        it('should deposit, add collateral, borrow and withdraw through Magnetar without withdraw', async () => {
            const {
                weth,
                wethUsdcSingularity,
                usdc,
                eoa1,
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
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
                .depositAddCollateralAndBorrowFromMarket({
                    market: wethUsdcSingularity.address,
                    user: eoa1.address,
                    collateralAmount: usdcMintVal,
                    borrowAmount: borrowAmount,
                    extractFromSender: true,
                    deposit: true,
                    withdrawParams: {
                        withdraw: false,
                        withdrawLzFeeAmount: 0,
                        withdrawOnOtherChain: false,
                        withdrawLzChainId: 0,
                        withdrawAdapterParams: '0x',
                        unwrap: false,
                        refundAddress: eoa1.address,
                        zroPaymentAddress: hre.ethers.constants.AddressZero,
                    },
                    valueAmount: 0,
                });
        });

        it('should add collateral, borrow and withdraw through Magnetar', async () => {
            const {
                weth,
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
            } = await loadFixture(register);

            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
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
                .depositAddCollateralAndBorrowFromMarket(
                    {
                        market: wethUsdcSingularity.address,
                        user: eoa1.address,
                        collateralAmount: usdcMintVal,
                        borrowAmount: borrowAmount,
                        extractFromSender: true,
                        deposit: false,
                        withdrawParams: {
                            withdraw: true,
                            withdrawLzFeeAmount: 0,
                            withdrawOnOtherChain: false,
                            withdrawLzChainId: 0,
                            withdrawAdapterParams: ethers.utils.solidityPack(
                                ['uint16', 'uint256'],
                                [1, 1000000],
                            ),
                            unwrap: false,
                            refundAddress: eoa1.address,
                            zroPaymentAddress: hre.ethers.constants.AddressZero,
                        },
                        valueAmount: 0,
                    },
                    // wethUsdcSingularity.address,
                    // eoa1.address,
                    // usdcMintVal,
                    // borrowAmount,
                    // true,
                    // false,
                    // {
                    //     withdraw: true,
                    //     withdrawLzFeeAmount: 0,
                    //     withdrawOnOtherChain: false,
                    //     withdrawLzChainId: 0,
                    // withdrawAdapterParams: ethers.utils.solidityPack(
                    //     ['uint16', 'uint256'],
                    //     [1, 1000000],
                    // ),
                    // },
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
                initContracts,
                magnetar,
                __wethUsdcPrice,
                approveTokensAndSetBarApproval,
                wethDepositAndAddAsset,
                yieldBox,
            } = await loadFixture(register);

            const assetId = await wethUsdcSingularity.assetId();
            await initContracts(); // To prevent `Singularity: below minimum`

            const borrowAmount = ethers.BigNumber.from((1e17).toString());
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
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
                .depositAddCollateralAndBorrowFromMarket(
                    {
                        market: wethUsdcSingularity.address,
                        user: eoa1.address,
                        collateralAmount: usdcMintVal,
                        borrowAmount: borrowAmount,
                        extractFromSender: true,
                        deposit: true,
                        withdrawParams: {
                            withdraw: true,
                            withdrawLzFeeAmount: 0,
                            withdrawOnOtherChain: false,
                            withdrawLzChainId: 0,
                            withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                            unwrap: false,
                            refundAddress: eoa1.address,
                            zroPaymentAddress: hre.ethers.constants.AddressZero,
                        },
                        valueAmount: 0,
                    },
                    // wethUsdcSingularity.address,
                    // eoa1.address,
                    // usdcMintVal,
                    // borrowAmount,
                    // true,
                    // true,
                    // {
                    //     withdraw: true,
                    //     withdrawLzFeeAmount: 0,
                    //     withdrawOnOtherChain: false,
                    //     withdrawLzChainId: 0,
                    //     withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                    // },
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
                    await yieldBox.toShare(
                        assetId,
                        userBorrowPart.mul(2),
                        true,
                    ),
                );
            await magnetar
                .connect(eoa1)
                .depositRepayAndRemoveCollateralFromMarket(
                    {
                        market: wethUsdcSingularity.address,
                        user: eoa1.address,
                        depositAmount: userBorrowPart.mul(2),
                        repayAmount: userBorrowPart,
                        collateralAmount: 0,
                        extractFromSender: true,
                        withdrawCollateralParams: {
                            withdraw: true,
                            withdrawLzFeeAmount: 0,
                            withdrawOnOtherChain: false,
                            withdrawLzChainId: 0,
                            withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                            unwrap: false,
                            refundAddress: eoa1.address,
                            zroPaymentAddress: hre.ethers.constants.AddressZero,
                        },
                        valueAmount: 0,
                    },
                    // wethUsdcSingularity.address,
                    // eoa1.address,
                    // userBorrowPart.mul(2),
                    // userBorrowPart,
                    // 0,
                    // true,
                    // {
                    //     withdraw: false,
                    //     withdrawLzFeeAmount: 0,
                    //     withdrawOnOtherChain: false,
                    //     withdrawLzChainId: 0,
                    //     withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                    // },
                );
        });

        it('should deposit, repay, remove collateral and withdraw through Magnetar', async () => {
            const {
                usdcAssetId,
                weth,
                wethUsdcSingularity,
                usdc,
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
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                10,
            );
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
                .depositAddCollateralAndBorrowFromMarket(
                    {
                        market: wethUsdcSingularity.address,
                        user: eoa1.address,
                        collateralAmount: usdcMintVal,
                        borrowAmount: borrowAmount,
                        extractFromSender: true,
                        deposit: true,
                        withdrawParams: {
                            withdraw: true,
                            withdrawLzFeeAmount: 0,
                            withdrawOnOtherChain: false,
                            withdrawLzChainId: 0,
                            withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                            unwrap: false,
                            refundAddress: eoa1.address,
                            zroPaymentAddress: hre.ethers.constants.AddressZero,
                        },
                        valueAmount: 0,
                    },
                    // wethUsdcSingularity.address,
                    // eoa1.address,
                    // usdcMintVal,
                    // borrowAmount,
                    // true,
                    // true,
                    // {
                    //     withdraw: true,
                    //     withdrawLzFeeAmount: 0,
                    //     withdrawOnOtherChain: false,
                    //     withdrawLzChainId: 0,
                    //     withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                    // },
                );

            const userBorrowPart = await wethUsdcSingularity.userBorrowPart(
                eoa1.address,
            );

            const collateralShare =
                await wethUsdcSingularity.userCollateralShare(eoa1.address);
            const collateralAmount = await yieldBox.toAmount(
                usdcAssetId,
                collateralShare,
                false,
            );

            await weth.connect(eoa1).freeMint(userBorrowPart.mul(2));

            await weth
                .connect(eoa1)
                .approve(magnetar.address, userBorrowPart.mul(2));

            await wethUsdcSingularity
                .connect(eoa1)
                .approveBorrow(
                    magnetar.address,
                    await yieldBox.toShare(
                        collateralId,
                        collateralAmount,
                        true,
                    ),
                );

            await magnetar
                .connect(eoa1)
                .depositRepayAndRemoveCollateralFromMarket(
                    {
                        market: wethUsdcSingularity.address,
                        user: eoa1.address,
                        depositAmount: userBorrowPart.mul(2),
                        repayAmount: userBorrowPart,
                        collateralAmount,
                        extractFromSender: true,
                        withdrawCollateralParams: {
                            withdraw: true,
                            withdrawLzFeeAmount: 0,
                            withdrawOnOtherChain: false,
                            withdrawLzChainId: 0,
                            withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                            unwrap: false,
                            refundAddress: eoa1.address,
                            zroPaymentAddress: hre.ethers.constants.AddressZero,
                        },
                        valueAmount: 0,
                    },
                    // wethUsdcSingularity.address,
                    // eoa1.address,
                    // userBorrowPart.mul(2),
                    // userBorrowPart,
                    // collateralAmount,
                    // true,
                    // {
                    //     withdraw: false,
                    //     withdrawLzFeeAmount: 0,
                    //     withdrawOnOtherChain: false,
                    //     withdrawLzChainId: 0,
                    //     withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                    // },
                );
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
                cluster,
            } = await loadFixture(register);

            await initContracts();

            //set assets oracle
            const OracleMock = new OracleMock__factory(deployer);
            const usdoUsdcOracle = await OracleMock.deploy(
                'USDOUSDCOracle',
                'USDOUSDCOracle',
                ethers.utils.parseEther('1'),
            );
            await usdoUsdcOracle.deployed();
            await usdoUsdcOracle.set(ethers.utils.parseEther('1'));

            const setAssetOracleFn =
                wethBigBangMarket.interface.encodeFunctionData(
                    'setAssetOracle',
                    [usdoUsdcOracle.address, '0x'],
                );
            await bar.executeMarketFn(
                [wethBigBangMarket.address],
                [setAssetOracleFn],
                true,
            );

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

            const borrowAmount = ethers.BigNumber.from((1e18).toString()).mul(
                100,
            );
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                1000,
            );

            // We get asset
            await weth.freeMint(wethMintVal);

            // Approve tokens
            // await approveTokensAndSetBarApproval();
            await yieldBox.setApprovalForAll(wethUsdoSingularity.address, true);
            await weth.approve(magnetar.address, wethMintVal);
            await wethUsdoSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );

            await wethBigBangMarket.approveBorrow(
                magnetar.address,
                ethers.constants.MaxUint256,
            );

            await cluster.updateContract(0, wethUsdoSingularity.address, true);
            await cluster.updateContract(0, wethBigBangMarket.address, true);
            await magnetar.mintFromBBAndLendOnSGL({
                user: deployer.address,
                lendAmount: borrowAmount,
                mintData: {
                    mint: true,
                    mintAmount: wethMintVal,
                    collateralDepositData: {
                        deposit: true,
                        amount: wethMintVal,
                        extractFromSender: true,
                    },
                },
                depositData: {
                    deposit: false,
                    amount: 0,
                    extractFromSender: false,
                },
                lockData: {
                    lock: false,
                    amount: 0,
                    lockDuration: 0,
                    target: ethers.constants.AddressZero,
                    fraction: 0,
                },

                participateData: {
                    participate: false,
                    target: ethers.constants.AddressZero,
                    tOLPTokenId: 0,
                },

                externalContracts: {
                    singularity: wethUsdoSingularity.address,
                    magnetar: magnetar.address,
                    bigBang: wethBigBangMarket.address,
                },
            });

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
                cluster,
                deployer,
            } = await loadFixture(register);

            await initContracts();

            //set assets oracle
            const OracleMock = new OracleMock__factory(deployer);
            const usdoUsdcOracle = await OracleMock.deploy(
                'USDOUSDCOracle',
                'USDOUSDCOracle',
                ethers.utils.parseEther('1'),
            );
            await usdoUsdcOracle.deployed();
            await usdoUsdcOracle.set(ethers.utils.parseEther('1'));

            const setAssetOracleFn =
                wethBigBangMarket.interface.encodeFunctionData(
                    'setAssetOracle',
                    [usdoUsdcOracle.address, '0x'],
                );
            await bar.executeMarketFn(
                [wethBigBangMarket.address],
                [setAssetOracleFn],
                true,
            );

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

            const borrowAmount = ethers.BigNumber.from((1e18).toString()).mul(
                100,
            );
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                1000,
            );

            await usd0.mint(deployer.address, borrowAmount.mul(2));
            // We get asset
            await weth.freeMint(wethMintVal);

            // Approve tokens
            // await approveTokensAndSetBarApproval();
            await yieldBox.setApprovalForAll(wethUsdoSingularity.address, true);
            await weth.approve(magnetar.address, wethMintVal);
            await wethUsdoSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );
            await wethBigBangMarket.approveBorrow(
                magnetar.address,
                ethers.constants.MaxUint256,
            );

            const borrowFeeUpdateFn =
                wethBigBangMarket.interface.encodeFunctionData(
                    'setMarketConfig',
                    [
                        ethers.constants.AddressZero,
                        '0x',
                        ethers.constants.AddressZero,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                    ],
                );
            await bar.executeMarketFn(
                [wethBigBangMarket.address],
                [borrowFeeUpdateFn],
                true,
            );

            await cluster.updateContract(0, wethUsdoSingularity.address, true);
            await cluster.updateContract(0, wethBigBangMarket.address, true);
            await magnetar.mintFromBBAndLendOnSGL({
                user: deployer.address,
                lendAmount: borrowAmount,
                mintData: {
                    mint: true,
                    mintAmount: wethMintVal,
                    collateralDepositData: {
                        deposit: true,
                        amount: wethMintVal,
                        extractFromSender: true,
                    },
                },
                depositData: {
                    deposit: false,
                    amount: 0,
                    extractFromSender: false,
                },
                lockData: {
                    lock: false,
                    amount: 0,
                    lockDuration: 0,
                    target: ethers.constants.AddressZero,
                    fraction: 0,
                },

                participateData: {
                    participate: false,
                    target: ethers.constants.AddressZero,
                    tOLPTokenId: 0,
                },

                externalContracts: {
                    singularity: wethUsdoSingularity.address,
                    magnetar: magnetar.address,
                    bigBang: wethBigBangMarket.address,
                },
            });

            await usd0.approve(yieldBox.address, ethers.constants.MaxUint256);
            await yieldBox.depositAsset(
                usdoAssetId,
                deployer.address,
                deployer.address,
                borrowAmount,
                0,
            );
            const wethBalanceBefore = await weth.balanceOf(deployer.address);
            const fraction = await wethUsdoSingularity.balanceOf(
                deployer.address,
            );
            const fractionAmount = await yieldBox.toAmount(
                usdoAssetId,
                fraction,
                false,
            );
            const totalBingBangCollateral =
                await wethBigBangMarket.userCollateralShare(deployer.address);

            const totalBingBangCollateralAmount = await yieldBox.toAmount(
                await wethBigBangMarket.collateralId(),
                totalBingBangCollateral,
                false,
            );

            // await expect(
            //     magnetar.exitPositionAndRemoveCollateral(
            //         deployer.address,
            //         {
            //             magnetar: magnetar.address,
            //             singularity: wethUsdoSingularity.address,
            //             bigBang: wethBigBangMarket.address,
            //         },
            //         {
            //             removeAssetFromSGL: true,
            //             removeAmount: fractionAmount,
            //             repayAssetOnBB: true,
            //             repayAmount: fractionAmount,
            //             removeCollateralFromBB: true,
            //             collateralAmount: totalBingBangCollateralAmount,
            //             exitData: {
            //                 exit: false,
            //                 oTAPTokenID: 0,
            //                 target: ethers.constants.AddressZero,
            //             },
            //             unlockData: {
            //                 unlock: false,
            //                 target: ethers.constants.AddressZero,
            //                 tokenId: 0,
            //             },
            //             assetWithdrawData: {
            //                 withdraw: false,
            //                 withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
            //                 withdrawLzChainId: 0,
            //                 withdrawLzFeeAmount: 0,
            //                 withdrawOnOtherChain: false,
            //             },
            //             collateralWithdrawData: {
            //                 withdraw: false,
            //                 withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
            //                 withdrawLzChainId: 0,
            //                 withdrawLzFeeAmount: 0,
            //                 withdrawOnOtherChain: false,
            //             },
            //         },
            //     ),
            // ).to.be.revertedWith('SGL: min limit');

            await cluster.updateContract(1, wethBigBangMarket.address, true);
            await cluster.updateContract(1, wethUsdoSingularity.address, true);
            await magnetar.exitPositionAndRemoveCollateral({
                user: deployer.address,
                externalData: {
                    magnetar: magnetar.address,
                    singularity: wethUsdoSingularity.address,
                    bigBang: wethBigBangMarket.address,
                },
                removeAndRepayData: {
                    removeAssetFromSGL: true,
                    removeAmount: fractionAmount.div(2),
                    repayAssetOnBB: true,
                    repayAmount: await yieldBox.toAmount(
                        usdoAssetId,
                        fraction.div(3),
                        false,
                    ),
                    removeCollateralFromBB: true,
                    collateralAmount: totalBingBangCollateralAmount.div(5),
                    exitData: {
                        exit: false,
                        oTAPTokenID: 0,
                        target: ethers.constants.AddressZero,
                    },
                    unlockData: {
                        unlock: false,
                        target: ethers.constants.AddressZero,
                        tokenId: 0,
                    },
                    assetWithdrawData: {
                        withdraw: false,
                        withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                        withdrawLzChainId: 0,
                        withdrawLzFeeAmount: 0,
                        withdrawOnOtherChain: false,
                        refundAddress: deployer.address,
                        zroPaymentAddress: ethers.constants.AddressZero,
                        unwrap: false,
                    },
                    collateralWithdrawData: {
                        withdraw: true,
                        withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                        withdrawLzChainId: 0,
                        withdrawLzFeeAmount: 0,
                        withdrawOnOtherChain: false,
                        refundAddress: deployer.address,
                        zroPaymentAddress: ethers.constants.AddressZero,
                        unwrap: false,
                    },
                },
                valueAmount: 0,
            });

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
                cluster,
            } = await loadFixture(register);

            await initContracts();

            //set assets oracle
            const OracleMock = new OracleMock__factory(deployer);
            const usdoUsdcOracle = await OracleMock.deploy(
                'USDOUSDCOracle',
                'USDOUSDCOracle',
                ethers.utils.parseEther('1'),
            );
            await usdoUsdcOracle.deployed();
            await usdoUsdcOracle.set(ethers.utils.parseEther('1'));

            const setAssetOracleFn =
                wethBigBangMarket.interface.encodeFunctionData(
                    'setAssetOracle',
                    [usdoUsdcOracle.address, '0x'],
                );
            await bar.executeMarketFn(
                [wethBigBangMarket.address],
                [setAssetOracleFn],
                true,
            );

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

            const borrowAmount = ethers.BigNumber.from((1e18).toString()).mul(
                100,
            );
            const wethMintVal = ethers.BigNumber.from((1e18).toString()).mul(
                1000,
            );

            await usd0.mint(deployer.address, borrowAmount.mul(2));
            // We get asset
            await weth.freeMint(wethMintVal);

            // Approve tokens
            // await approveTokensAndSetBarApproval();
            await yieldBox.setApprovalForAll(wethUsdoSingularity.address, true);
            await weth.approve(magnetar.address, wethMintVal);
            await wethUsdoSingularity.approve(
                magnetar.address,
                ethers.constants.MaxUint256,
            );
            await wethBigBangMarket.approveBorrow(
                magnetar.address,
                ethers.constants.MaxUint256,
            );

            await cluster.updateContract(0, wethBigBangMarket.address, true);
            await cluster.updateContract(0, wethUsdoSingularity.address, true);
            await magnetar.mintFromBBAndLendOnSGL({
                user: deployer.address,
                lendAmount: borrowAmount,
                mintData: {
                    mint: true,
                    mintAmount: wethMintVal,
                    collateralDepositData: {
                        deposit: true,
                        amount: wethMintVal,
                        extractFromSender: true,
                    },
                },
                depositData: {
                    deposit: false,
                    amount: 0,
                    extractFromSender: false,
                },
                lockData: {
                    lock: false,
                    amount: 0,
                    lockDuration: 0,
                    target: ethers.constants.AddressZero,
                    fraction: 0,
                },
                participateData: {
                    participate: false,
                    target: ethers.constants.AddressZero,
                    tOLPTokenId: 0,
                },
                externalContracts: {
                    singularity: wethUsdoSingularity.address,
                    magnetar: magnetar.address,
                    bigBang: wethBigBangMarket.address,
                },
            });

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
            const fraction = await wethUsdoSingularity.balanceOf(
                deployer.address,
            );
            const fractionAmount = await yieldBox.toAmount(
                usdoAssetId,
                fraction,
                false,
            );
            const totalBingBangCollateral =
                await wethBigBangMarket.userCollateralShare(deployer.address);
            const totalBingBangCollateralAmount = await yieldBox.toAmount(
                await wethBigBangMarket.collateralId(),
                totalBingBangCollateral,
                false,
            );

            await cluster.updateContract(1, wethBigBangMarket.address, true);
            await cluster.updateContract(1, wethUsdoSingularity.address, true);
            await magnetar.exitPositionAndRemoveCollateral({
                user: deployer.address,
                externalData: {
                    magnetar: magnetar.address,
                    singularity: wethUsdoSingularity.address,
                    bigBang: wethBigBangMarket.address,
                },
                removeAndRepayData: {
                    removeAssetFromSGL: true,
                    removeAmount: fractionAmount.div(2),
                    repayAssetOnBB: true,
                    repayAmount: await yieldBox.toAmount(
                        usdoAssetId,
                        fraction.div(3),
                        false,
                    ),
                    removeCollateralFromBB: true,
                    collateralAmount: totalBingBangCollateralAmount.div(5),
                    exitData: {
                        exit: false,
                        oTAPTokenID: 0,
                        target: ethers.constants.AddressZero,
                    },
                    unlockData: {
                        unlock: false,
                        target: ethers.constants.AddressZero,
                        tokenId: 0,
                    },
                    assetWithdrawData: {
                        withdraw: false,
                        withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                        withdrawLzChainId: 0,
                        withdrawLzFeeAmount: 0,
                        withdrawOnOtherChain: false,
                        refundAddress: deployer.address,
                        zroPaymentAddress: ethers.constants.AddressZero,
                        unwrap: false,
                    },
                    collateralWithdrawData: {
                        withdraw: false,
                        withdrawAdapterParams: ethers.utils.toUtf8Bytes(''),
                        withdrawLzChainId: 0,
                        withdrawLzFeeAmount: 0,
                        withdrawOnOtherChain: false,
                        refundAddress: deployer.address,
                        zroPaymentAddress: ethers.constants.AddressZero,
                        unwrap: false,
                    },
                },
                valueAmount: 0,
            });
            const wethCollateralAfter =
                await wethBigBangMarket.userCollateralShare(deployer.address);

            expect(wethCollateralAfter.lt(wethCollateralBefore)).to.be.true;

            const wethBalanceAfter = await weth.balanceOf(deployer.address);
            expect(wethBalanceAfter.eq(0)).to.be.true;
        });
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

async function getChainId(): Promise<number> {
    const chainIdHex = await hre.network.provider.send('eth_chainId', []);
    return BN(chainIdHex).toNumber();
}

async function setupUsd0Environment(
    mediumRiskMC: any,
    yieldBox: any,
    cluster: string,
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

    const USDOLeverageModule = new USDOLeverageModule__factory(deployer);
    const USDOLeverageDestinationModule =
        new USDOLeverageDestinationModule__factory(deployer);
    const USDOMarketModule = new USDOMarketModule__factory(deployer);
    const USDOMarketDestinationModule =
        new USDOMarketDestinationModule__factory(deployer);
    const USDOOptionsModule = new USDOOptionsModule__factory(deployer);
    const USDOOptionsDestinationModule =
        new USDOOptionsDestinationModule__factory(deployer);
    const USDOGenericModule = new USDOGenericModule__factory(deployer);

    const usdo_leverage_src = await USDOLeverageModule.deploy(
        lzEndpointSrc.address,
        yieldBox.address,
        cluster,
    );
    const usdo_leverage_destination_src =
        await USDOLeverageDestinationModule.deploy(
            lzEndpointSrc.address,
            yieldBox.address,
            cluster,
        );
    const usdo_market_src = await USDOMarketModule.deploy(
        lzEndpointSrc.address,
        yieldBox.address,
        cluster,
    );
    const usdo_market_destination_src =
        await USDOMarketDestinationModule.deploy(
            lzEndpointSrc.address,
            yieldBox.address,
            cluster,
        );
    const usdo_options_src = await USDOOptionsModule.deploy(
        lzEndpointSrc.address,
        yieldBox.address,
        cluster,
    );
    const usdo_options_destination_src =
        await USDOOptionsDestinationModule.deploy(
            lzEndpointSrc.address,
            yieldBox.address,
            cluster,
        );
    const usdo_neneric_src = await USDOGenericModule.deploy(
        lzEndpointSrc.address,
        yieldBox.address,
        cluster,
    );

    //deploy usd0 tokens
    const USDO = new USDO__factory(deployer);

    const usd0Src = await USDO.deploy(
        lzEndpointSrc.address,
        yieldBox.address,
        cluster,
        deployer.address,
        usdo_leverage_src.address,
        usdo_leverage_destination_src.address,
        usdo_market_src.address,
        usdo_market_destination_src.address,
        usdo_options_src.address,
        usdo_options_destination_src.address,
        usdo_neneric_src.address,
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

    const usdo_leverage_dst = await USDOLeverageModule.deploy(
        lzEndpointDst.address,
        yieldBox.address,
        cluster,
    );
    const usdo_leverage_destination_dst =
        await USDOLeverageDestinationModule.deploy(
            lzEndpointDst.address,
            yieldBox.address,
            cluster,
        );
    const usdo_market_dst = await USDOMarketModule.deploy(
        lzEndpointDst.address,
        yieldBox.address,
        cluster,
    );
    const usdo_market_destination_dst =
        await USDOMarketDestinationModule.deploy(
            lzEndpointDst.address,
            yieldBox.address,
            cluster,
        );
    const usdo_options_dst = await USDOOptionsModule.deploy(
        lzEndpointDst.address,
        yieldBox.address,
        cluster,
    );
    const usdo_options_destination_dst =
        await USDOOptionsDestinationModule.deploy(
            lzEndpointDst.address,
            yieldBox.address,
            cluster,
        );
    const usdo_generic_dst = await USDOGenericModule.deploy(
        lzEndpointDst.address,
        yieldBox.address,
        cluster,
    );

    const usd0Dst = await USDO.deploy(
        lzEndpointDst.address,
        yieldBox.address,
        cluster,
        deployer.address,
        usdo_leverage_dst.address,
        usdo_leverage_destination_dst.address,
        usdo_market_dst.address,
        usdo_market_destination_dst.address,
        usdo_options_dst.address,
        usdo_options_destination_dst.address,
        usdo_generic_dst.address,
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
