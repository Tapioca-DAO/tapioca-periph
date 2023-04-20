import { expect } from 'chai';
import hre, { ethers, config } from 'hardhat';
import { BN, register } from './test.utils';
import { signTypedMessage } from 'eth-sig-util';
import { fromRpcSig } from 'ethereumjs-utils';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

import LZEndpointMockArtifact from '../gitsub_tapioca-sdk/src/artifacts/tapioca-mocks/LZEndpointMock.json';
import MarketsProxyArtifact from '../gitsub_tapioca-sdk/src/artifacts/tapioca-bar/MarketsProxy.json';
import SingularityArtifact from '../gitsub_tapioca-sdk/src/artifacts/tapioca-bar/Singularity.json';

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
} from '../gitsub_tapioca-sdk/src/typechain/tapioca-mocks';

const MAX_DEADLINE = 9999999999999;

const symbol = 'MTKN';
const version = '1';

describe.only('MagnetarV2', () => {
    it('should test send from', async () => {
        const {
            deployer,
            bar,
            proxyDeployer,
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
            proxySrc,
            proxyDst,
            singularitySrc,
            singularityDst,
            lzEndpointSrc,
            lzEndpointDst,
            usd0Src,
            usd0Dst,
            usd0DstId,
            usd0SrcId,
        } = await setupUsd0Environment(
            proxyDeployer,
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
    proxyDeployer: any,
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

    const saltSrc = ethers.utils.formatBytes32String('ProxySrc');
    const saltDst = ethers.utils.formatBytes32String('ProxyDst');

    await proxyDeployer.deployWithCreate2(lzEndpointSrc.address, saltSrc);
    await proxyDeployer.deployWithCreate2(lzEndpointDst.address, saltDst);

    const proxySrc = new ethers.Contract(
        await proxyDeployer.proxies(0),
        MarketsProxyArtifact.abi,
        ethers.provider,
    ).connect(deployer);
    const proxyDst = new ethers.Contract(
        await proxyDeployer.proxies(1),
        MarketsProxyArtifact.abi,
        ethers.provider,
    ).connect(deployer);

    lzEndpointSrc.setDestLzEndpoint(proxyDst.address, lzEndpointDst.address);
    lzEndpointDst.setDestLzEndpoint(proxySrc.address, lzEndpointSrc.address);

    await proxySrc.setTrustedRemote(
        chainIdDst,
        ethers.utils.solidityPack(
            ['address', 'address'],
            [proxyDst.address, proxySrc.address],
        ),
    );

    await proxyDst.setTrustedRemote(
        chainIdSrc,
        ethers.utils.solidityPack(
            ['address', 'address'],
            [proxySrc.address, proxyDst.address],
        ),
    );

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

    await proxySrc.updateMarketStatus(singularitySrc.address, true);
    await proxyDst.updateMarketStatus(singularityDst.address, true);

    const proxySrcSingularitySrcStatus = await proxySrc.markets(
        singularitySrc.address,
    );
    const proxySrcSingularityDstStatus = await proxySrc.markets(
        singularityDst.address,
    );
    expect(proxySrcSingularitySrcStatus).to.be.true;
    expect(proxySrcSingularityDstStatus).to.be.false;

    const proxyDstSingularitySrcStatus = await proxyDst.markets(
        singularitySrc.address,
    );
    const proxyDstSingularityDstStatus = await proxyDst.markets(
        singularityDst.address,
    );
    expect(proxyDstSingularitySrcStatus).to.be.false;
    expect(proxyDstSingularityDstStatus).to.be.true;
    return {
        proxySrc,
        proxyDst,
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