import { time, reset } from '@nomicfoundation/hardhat-network-helpers';
import { BigNumber, BigNumberish, Signature, Wallet } from 'ethers';
import hre, { ethers, network } from 'hardhat';
import { splitSignature } from 'ethers/lib/utils';
import SingularityArtifact from '@tapioca-sdk/artifacts/tapioca-bar/Singularity.json';
import BigBangArtifact from '@tapioca-sdk/artifacts/tapioca-bar/BigBang.json';

import {
    YieldBox__factory,
    YieldBoxURIBuilder__factory,
    ERC20WithoutStrategy__factory,
    YieldBox,
} from '@tapioca-sdk/typechain/YieldBox';
import {
    Singularity,
    Penrose,
    Penrose__factory,
    Singularity__factory,
    SGLLiquidation__factory,
    USDO,
    USDO__factory,
    BigBang__factory,
    SGLCollateral__factory,
    SGLBorrow__factory,
    SGLLeverage__factory,
    USDOLeverageModule__factory,
    USDOMarketModule__factory,
    USDOOptionsModule__factory,
    BBLiquidation__factory,
    BBCollateral__factory,
    BBBorrow__factory,
    BBLeverage__factory,
    USDOLeverageDestinationModule__factory,
    USDOMarketDestinationModule__factory,
    USDOOptionsDestinationModule__factory,
    USDOGenericModule__factory,
    BigBang,
} from '@tapioca-sdk/typechain/Tapioca-bar';

import {
    OracleMock__factory,
    ERC20Mock__factory,
    ERC20Mock,
    UniswapV2Factory__factory,
    UniswapV2Router02__factory,
    OracleMock,
    LZEndpointMock__factory,
    UniswapV2Factory,
    UniswapV2Router02,
    CurvePoolMock__factory,
} from '@tapioca-sdk/typechain/tapioca-mocks';
import { CurveSwapper__factory } from '@typechain/index';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { CurveStableToUsdoBidder } from 'tapioca-sdk/dist/typechain/tapioca-periphery';

ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR);
const verifyEtherscanQueue: { address: string; args: any[] }[] = [];

export async function impersonateAccount(address: string) {
    return network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [address],
    });
}

export function BN(n: BigNumberish) {
    return ethers.BigNumber.from(n);
}

export async function setBalance(addr: string, ether: number) {
    await ethers.provider.send('hardhat_setBalance', [
        addr,
        ethers.utils.hexStripZeros(ethers.utils.parseEther(String(ether))._hex),
    ]);
}

const __wethUsdcPrice = BN(1000).mul((1e18).toString());

const verifyEtherscan = async (
    address: string,
    args: any[],
    staging?: boolean,
) => {
    if (staging) {
        verifyEtherscanQueue.push({ address, args });
    }
};

async function registerERC20Tokens(deployer: any, staging?: boolean) {
    const mintLimitERC20 = ethers.BigNumber.from((1e18).toString()).mul(1e15);
    const supplyStart = ethers.BigNumber.from((1e18).toString()).mul(1e9);

    const ERC20Mock = new ERC20Mock__factory(deployer);

    //Deploy USDC
    const usdc = await ERC20Mock.deploy(
        'USDC Mock',
        'USDCM',
        supplyStart,
        18,
        deployer.address,
    );
    log(
        `Deployed USDC ${usdc.address} with args [${supplyStart},18, ${mintLimitERC20}]`,
        staging,
    );
    await usdc.updateMintLimit(supplyStart);

    //Deploy TAP
    const tap = await ERC20Mock.deploy(
        'TAP Mock',
        'TAPM',
        supplyStart,
        18,
        deployer.address,
    );
    log(
        `Deployed TAP ${tap.address} with args [${supplyStart},18,${mintLimitERC20}]`,
        staging,
    );
    await tap.updateMintLimit(supplyStart);

    // Deploy WETH
    const weth = await ERC20Mock.deploy(
        'WETH Mock',
        'WETHM',
        supplyStart,
        18,
        deployer.address,
    );
    log(`Deployed WETH ${weth.address} with no arguments`, staging);
    await weth.updateMintLimit(supplyStart);

    await verifyEtherscan(
        usdc.address,
        [supplyStart, 18, mintLimitERC20],
        staging,
    );
    await verifyEtherscan(
        tap.address,
        [supplyStart, 18, mintLimitERC20],
        staging,
    );
    await verifyEtherscan(weth.address, [mintLimitERC20], staging);

    return { usdc, weth, tap };
}

async function registerYieldBox(deployer: any, staging?: boolean) {
    const YieldBoxURIBuilder = new YieldBoxURIBuilder__factory(deployer);
    const YieldBox = new YieldBox__factory(deployer);

    // Deploy URIBuilder
    const uriBuilder = await YieldBoxURIBuilder.deploy();
    log(
        `Deployed YieldBoxURIBuilder ${uriBuilder.address} with no arguments`,
        staging,
    );

    // Deploy yieldBox
    const yieldBox = await YieldBox.deploy(
        ethers.constants.AddressZero,
        uriBuilder.address,
    );
    log(
        `Deployed YieldBox ${yieldBox.address} with args [${ethers.constants.AddressZero}, ${uriBuilder.address}] `,
        staging,
    );

    await verifyEtherscan(uriBuilder.address, [], staging);
    await verifyEtherscan(
        yieldBox.address,
        [ethers.constants.AddressZero, uriBuilder.address],
        staging,
    );

    return { uriBuilder, yieldBox };
}

async function registerPenrose(
    deployer: any,
    yieldBox: string,
    cluster: string,
    tapAddress: string,
    wethAddress: string,
    staging?: boolean,
) {
    const Penrose = new Penrose__factory(deployer);

    const bar = await Penrose.deploy(
        yieldBox,
        cluster,
        tapAddress,
        wethAddress,
        1,
        deployer.address,
    );
    log(
        `Deployed Penrose ${bar.address} with args [${yieldBox}, ${tapAddress}, ${wethAddress}]`,
        staging,
    );
    await verifyEtherscan(
        bar.address,
        [yieldBox, tapAddress, wethAddress],
        staging,
    );

    return { bar };
}

async function setPenroseAssets(
    deployer: any,
    yieldBox: YieldBox,
    bar: Penrose,
    usdcAddress: string,
) {
    const wethAssetId = await bar.mainAssetId();

    const usdcStrategy = await createTokenEmptyStrategy(
        deployer,
        yieldBox.address,
        usdcAddress,
    );
    await (
        await yieldBox.registerAsset(1, usdcAddress, usdcStrategy.address, 0)
    ).wait();
    const usdcAssetId = await yieldBox.ids(
        1,
        usdcAddress,
        usdcStrategy.address,
        0,
    );

    return {
        wethAssetId,
        usdcAssetId,
        usdcStrategy,
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

async function uniV2EnvironnementSetup(
    deployer: any,
    weth: ERC20Mock,
    usdc: ERC20Mock,
    tap: ERC20Mock,
    staging?: boolean,
) {
    // Deploy Uni factory, create pair and add liquidity
    const { __uniFactory, __uniRouter } = await registerUniswapV2(
        deployer,
        staging,
    );
    await (await __uniFactory.createPair(weth.address, usdc.address)).wait();

    // Create WETH/USDC LP
    const wethPairAmount = ethers.BigNumber.from(1e6).mul((1e18).toString());
    const usdcPairAmount = wethPairAmount.mul(
        __wethUsdcPrice.div((1e18).toString()),
    );
    await (await weth.mintTo(deployer.address, wethPairAmount)).wait();
    await (await usdc.mintTo(deployer.address, usdcPairAmount)).wait();

    await (await weth.approve(__uniRouter.address, wethPairAmount)).wait();
    await (await usdc.approve(__uniRouter.address, usdcPairAmount)).wait();
    await (
        await __uniRouter.addLiquidity(
            weth.address,
            usdc.address,
            wethPairAmount,
            usdcPairAmount,
            wethPairAmount,
            usdcPairAmount,
            deployer.address,
            ethers.utils.parseEther('10'),
        )
    ).wait();
    const __wethUsdcMockPair = await __uniFactory.getPair(
        weth.address,
        usdc.address,
    );

    // Create WETH/TAP LP
    await (await weth.mintTo(deployer.address, wethPairAmount)).wait();
    await (await tap.mintTo(deployer.address, wethPairAmount)).wait();

    await (await weth.approve(__uniRouter.address, wethPairAmount)).wait();
    await (await tap.approve(__uniRouter.address, wethPairAmount)).wait();
    await (
        await __uniRouter.addLiquidity(
            weth.address,
            tap.address,
            wethPairAmount,
            wethPairAmount,
            wethPairAmount,
            wethPairAmount,
            deployer.address,
            ethers.utils.parseEther('10'),
        )
    ).wait();
    const __wethTapMockPair = await __uniFactory.getPair(
        weth.address,
        tap.address,
    );

    return {
        __wethUsdcMockPair,
        __wethTapMockPair,
        __uniFactory,
        __uniRouter,
    };
}

async function registerUniswapV2(deployer: any, staging?: boolean) {
    const UniswapV2Factory = new UniswapV2Factory__factory(deployer);

    const __uniFactoryFee = ethers.Wallet.createRandom();
    const __uniFactory = await UniswapV2Factory.deploy(__uniFactoryFee.address);
    log(
        `Deployed UniswapV2Factory ${__uniFactory.address} with args [${__uniFactoryFee.address}]`,
        staging,
    );

    const UniswapV2Router02 = new UniswapV2Router02__factory(deployer);
    const __uniRouter = await UniswapV2Router02.deploy(
        __uniFactory.address,
        ethers.constants.AddressZero,
    );
    log(
        `Deployed UniswapV2Router02 ${__uniRouter.address} with args [${__uniFactory.address}, ${ethers.constants.AddressZero}]`,
        staging,
    );

    return { __uniFactory, __uniFactoryFee, __uniRouter };
}

async function deployMediumRiskMC(
    deployer: any,
    bar: Penrose,
    staging?: boolean,
) {
    const Singularity = new Singularity__factory(deployer);

    const mediumRiskMC = await Singularity.deploy();
    log(
        `Deployed MediumRiskMC ${mediumRiskMC.address} with no arguments`,
        staging,
    );

    await (
        await bar.registerSingularityMasterContract(mediumRiskMC.address, 1)
    ).wait();
    log('MediumRiskMC was set on Penrose', staging);

    await verifyEtherscan(mediumRiskMC.address, [], staging);

    return { mediumRiskMC };
}

async function deployMediumRiskBigBangMC(
    deployer: any,
    bar: Penrose,
    staging?: boolean,
) {
    const BigBang = new BigBang__factory(deployer);
    const mediumRiskBigBangMC = await BigBang.deploy();
    log(
        `Deployed MediumRiskBigBangMC ${mediumRiskBigBangMC.address} with no arguments`,
        staging,
    );

    await (
        await bar.registerBigBangMasterContract(mediumRiskBigBangMC.address, 1)
    ).wait();
    log('MediumRiskMC was set on Penrose', staging);

    await verifyEtherscan(mediumRiskBigBangMC.address, [], staging);

    return { mediumRiskBigBangMC };
}

async function registerSingularity(
    deployer: any,
    mediumRiskMC: string,
    yieldBox: YieldBox,
    bar: Penrose,
    weth: ERC20Mock,
    wethAssetId: BigNumberish,
    usdc: ERC20Mock,
    usdcAssetId: BigNumberish,
    wethUsdcOracle: OracleMock,
    exchangeRatePrecision?: BigNumberish,
    staging?: boolean,
) {
    const SGLLiquidation = new SGLLiquidation__factory(deployer);
    const _sglLiquidationModule = await SGLLiquidation.deploy();
    log(
        `Deployed WethUsdcSGLLiquidationModule ${_sglLiquidationModule.address} with no arguments`,
        staging,
    );

    const SGLCollateral = new SGLCollateral__factory(deployer);
    const _sglCollateralModule = await SGLCollateral.deploy();

    const SGLBorrow = new SGLBorrow__factory(deployer);
    const _sglBorrowModule = await SGLBorrow.deploy();

    const SGLLeverage = new SGLLeverage__factory(deployer);
    const _sglLeverageModule = await SGLLeverage.deploy();

    const data = new ethers.utils.AbiCoder().encode(
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
            weth.address,
            wethAssetId,
            usdc.address,
            usdcAssetId,
            wethUsdcOracle.address,
            exchangeRatePrecision ?? 0,
            0,
            0,
            ethers.constants.AddressZero,
        ],
    );
    await (await bar.registerSingularity(mediumRiskMC, data, true)).wait();
    log('WethUsdcSingularity registered on Penrose', staging);

    const singularityMarket = new ethers.Contract(
        await bar.clonesOf(
            mediumRiskMC,
            (await bar.clonesOfCount(mediumRiskMC)).sub(1),
        ),
        SingularityArtifact.abi,
        ethers.provider,
    ).connect(deployer);

    await verifyEtherscan(singularityMarket.address, [], staging);

    return {
        singularityMarket,
        _sglLiquidationModule,
        _sglCollateralModule,
        _sglBorrowModule,
        _sglLeverageModule,
    };
}

async function registerLiquidationQueue(
    deployer: any,
    bar: Penrose,
    singularity: Singularity,
    feeCollector: string,
    staging?: boolean,
) {
    const LiquidationQueueFactory = await ethers.getContractFactory(
        'LiquidationQueue',
    );
    const liquidationQueue = await LiquidationQueueFactory.deploy();
    log(
        `Deployed LiquidationQueue ${liquidationQueue.address} with no arguments`,
        staging,
    );

    const LQ_META = {
        activationTime: 600, // 10min
        minBidAmount: ethers.BigNumber.from((1e18).toString()).mul(1), // 1 USDC
        closeToMinBidAmount: ethers.BigNumber.from((1e18).toString()).mul(202),
        defaultBidAmount: ethers.BigNumber.from((1e18).toString()).mul(400), // 400 USDC
        feeCollector,
        bidExecutionSwapper: ethers.constants.AddressZero,
        usdoSwapper: ethers.constants.AddressZero,
    };
    await liquidationQueue.init(LQ_META, singularity.address);
    log('LiquidationQueue initialized', staging);

    const payload = singularity.interface.encodeFunctionData(
        'setLiquidationQueueConfig',
        [
            liquidationQueue.address,
            ethers.constants.AddressZero,
            ethers.constants.AddressZero,
        ],
    );

    await (
        await bar.executeMarketFn([singularity.address], [payload], true)
    ).wait();
    log('WethUsdcLiquidationQueue was set for WethUsdcSingularity', staging);

    await verifyEtherscan(
        liquidationQueue.address,
        [BN(1e18).mul(1e9).toString()],
        staging,
    );

    return { liquidationQueue, LQ_META };
}

async function registerUsd0Contract(
    chainId: string,
    yieldBox: string,
    cluster: string,
    owner: any,
    staging?: boolean,
) {
    const LZEndpointMock = new LZEndpointMock__factory(owner);
    const lzEndpointContract = await LZEndpointMock.deploy(chainId);
    log(
        `Deployed LZEndpointMock ${lzEndpointContract.address} with args [${chainId}]`,
        staging,
    );
    await verifyEtherscan(lzEndpointContract.address, [chainId], staging);

    const USDOLeverageModule = new USDOLeverageModule__factory(owner);
    const usdo_leverage = await USDOLeverageModule.deploy(
        lzEndpointContract.address,
        yieldBox,
        cluster,
    );
    const USDOLeverageDestinationModule =
        new USDOLeverageDestinationModule__factory(owner);
    const usdo_leverage_destination =
        await USDOLeverageDestinationModule.deploy(
            lzEndpointContract.address,
            yieldBox,
            cluster,
        );

    const USDOMarketModule = new USDOMarketModule__factory(owner);
    const usdo_market = await USDOMarketModule.deploy(
        lzEndpointContract.address,
        yieldBox,
        cluster,
    );

    const USDOMarketDestinationModule =
        new USDOMarketDestinationModule__factory(owner);
    const usdo_market_destination = await USDOMarketDestinationModule.deploy(
        lzEndpointContract.address,
        yieldBox,
        cluster,
    );

    const USDOOptionsModule = new USDOOptionsModule__factory(owner);
    const usdo_options = await USDOOptionsModule.deploy(
        lzEndpointContract.address,
        yieldBox,
        cluster,
    );

    const USDOOptionsDestinationModule =
        new USDOOptionsDestinationModule__factory(owner);
    const usdo_options_destination = await USDOOptionsDestinationModule.deploy(
        lzEndpointContract.address,
        yieldBox,
        cluster,
    );

    const USDOGenericModule = new USDOGenericModule__factory(owner);
    const usdo_generic = await USDOGenericModule.deploy(
        lzEndpointContract.address,
        yieldBox,
        cluster,
    );

    const USDO = new USDO__factory(owner);
    const usd0 = await USDO.deploy(
        lzEndpointContract.address,
        yieldBox,
        cluster,
        owner.address,
        usdo_leverage.address,
        usdo_leverage_destination.address,
        usdo_market.address,
        usdo_market_destination.address,
        usdo_options.address,
        usdo_options_destination.address,
        usdo_generic.address,
    );
    log(
        `Deployed UDS0 ${usd0.address} with args [${lzEndpointContract.address},${yieldBox}]`,
        staging,
    );
    await verifyEtherscan(
        usd0.address,
        [lzEndpointContract.address, yieldBox],
        staging,
    );

    return { usd0, lzEndpointContract };
}

async function addUniV2Liquidity(
    deployerAddress: string,
    token1: ERC20Mock | any,
    token2: ERC20Mock | any,
    token1Amount: BigNumberish,
    token2Amount: BigNumberish,
    __uniFactory: UniswapV2Factory,
    __uniRouter: UniswapV2Router02,
    createPair?: boolean,
) {
    if (createPair) {
        await (
            await __uniFactory.createPair(token1.address, token2.address)
        ).wait();
    }

    if (token1.mintTo !== undefined) {
        await token1.mintTo(deployerAddress, token1Amount);
    } else {
        await token1.mint(deployerAddress, token1Amount);
    }

    if (token2.mintTo !== undefined) {
        await token2.mintTo(deployerAddress, token2Amount);
    } else {
        await token2.mint(deployerAddress, token2Amount);
    }

    await token1.approve(__uniRouter.address, token1Amount);
    await token2.approve(__uniRouter.address, token2Amount);
    await __uniRouter.addLiquidity(
        token1.address,
        token2.address,
        token1Amount,
        token2Amount,
        token1Amount,
        token2Amount,
        deployerAddress,
        ethers.utils.parseEther('10'),
    );
}

async function deployCurveStableToUsdoBidder(
    deployer: any,
    bar: Penrose,
    usdc: ERC20Mock,
    usdo: USDO,
    staging?: boolean,
) {
    const CurvePoolMock = new CurvePoolMock__factory(deployer);
    const curvePoolMock = await CurvePoolMock.deploy(
        usdo.address,
        usdc.address,
    );

    await usdo.setMinterStatus(curvePoolMock.address, true);
    log(
        `Deployed CurvePoolMock ${curvePoolMock.address} with args [${usdo.address},${usdc.address}]`,
        staging,
    );

    const CurveSwapper = new CurveSwapper__factory(deployer);
    const curveSwapper = await CurveSwapper.deploy(
        curvePoolMock.address,
        bar.address,
    );
    log(
        `Deployed CurveSwapper ${curveSwapper.address} with args [${curvePoolMock.address},${bar.address}]`,
        staging,
    );

    await verifyEtherscan(
        curvePoolMock.address,
        [usdo.address, usdc.address],
        staging,
    );
    await verifyEtherscan(
        curveSwapper.address,
        [curvePoolMock.address, bar.address],
        staging,
    );

    return { curveSwapper };
}

async function createWethUsd0Singularity(
    deployer: any,
    usd0: USDO,
    weth: ERC20Mock,
    bar: Penrose,
    usdoAssetId: any,
    wethAssetId: any,
    mediumRiskMC: Singularity,
    yieldBox: YieldBox,
    stableToUsdoBidder: CurveStableToUsdoBidder,
    exchangePrecision?: BigNumberish,
    staging?: boolean,
) {
    const SGLLiquidation = new SGLLiquidation__factory(deployer);
    const _sglLiquidationModule = await SGLLiquidation.deploy();
    log(
        `Deployed WethUsd0SGLLiquidationModule ${_sglLiquidationModule.address} with no arguments`,
        staging,
    );

    const SGLCollateral = new SGLCollateral__factory(deployer);
    const _sglCollateralModule = await SGLCollateral.deploy();

    const SGLBorrow = new SGLBorrow__factory(deployer);
    const _sglBorrowModule = await SGLBorrow.deploy();

    const SGLLeverage = new SGLLeverage__factory(deployer);
    const _sglLeverageModule = await SGLLeverage.deploy();

    // Deploy WethUSD0 mock oracle
    const OracleMock = new OracleMock__factory(deployer);
    const wethUsd0Oracle = await OracleMock.deploy(
        'WETHUSD0Mock',
        'WSM',
        (1e18).toString(),
    );
    log(
        `Deployed WethUsd0 mock oracle at ${wethUsd0Oracle.address} with no arguments`,
        staging,
    );

    const newPrice = __wethUsdcPrice.div(1000000);
    await wethUsd0Oracle.set(newPrice);
    log('Price was set for WethUsd0 mock oracle', staging);

    const data = new ethers.utils.AbiCoder().encode(
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
            wethUsd0Oracle.address,
            exchangePrecision,
            0,
            0,
            ethers.constants.AddressZero,
        ],
    );
    await bar.registerSingularity(mediumRiskMC.address, data, false);

    const clonesCount = await bar.clonesOfCount(mediumRiskMC.address);
    log(`Clones count of MediumRiskMC ${clonesCount}`, staging);

    const wethUsdoSingularity = new ethers.Contract(
        await bar.clonesOf(
            mediumRiskMC.address,
            (await bar.clonesOfCount(mediumRiskMC.address)).sub(1),
        ),
        SingularityArtifact.abi,
        ethers.provider,
    ).connect(deployer) as Singularity;
    log(
        `Deployed WethUsd0Singularity at ${wethUsdoSingularity.address} with no arguments`,
        staging,
    );

    //Deploy & set LiquidationQueue
    await usd0.setMinterStatus(wethUsdoSingularity.address, true);
    await usd0.setBurnerStatus(wethUsdoSingularity.address, true);
    log(
        'Updated Usd0 Minter and Burner status for WethUsd0Singularity',
        staging,
    );

    return { wethUsdoSingularity };
}

async function registerBigBangMarket(
    deployer: any,
    mediumRiskBigBangMC: string,
    yieldBox: YieldBox,
    bar: Penrose,
    collateral: ERC20Mock,
    collateralId: BigNumberish,
    oracle: OracleMock,
    exchangeRatePrecision?: BigNumberish,
    debtRateAgainstEth?: BigNumberish,
    debtRateMin?: BigNumberish,
    debtRateMax?: BigNumberish,
    debtStartPoint?: BigNumberish,
    staging?: boolean,
) {
    const BBLiquidation = new BBLiquidation__factory(deployer);
    const _bbLiquidationModule = await BBLiquidation.deploy();
    log(
        `Deployed BBLiquidationModule ${_bbLiquidationModule.address} with no arguments`,
        staging,
    );

    const BBCollateral = new BBCollateral__factory(deployer);
    const _bbCollateral = await BBCollateral.deploy();
    log(
        `Deployed BBCollateral ${_bbCollateral.address} with no arguments`,
        staging,
    );

    const BBBorrow = new BBBorrow__factory(deployer);
    const _bbBorrow = await BBBorrow.deploy();
    log(`Deployed BBBorrow ${_bbBorrow.address} with no arguments`, staging);

    const BBLeverage = new BBLeverage__factory(deployer);
    const _bbLeverage = await BBLeverage.deploy();
    log(
        `Deployed BBLeverage ${_bbLeverage.address} with no arguments`,
        staging,
    );

    const data = new ethers.utils.AbiCoder().encode(
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
            'uint256',
            'uint256',
            'uint256',
            'uint256',
            'uint256',
            'uint256',
            'address',
        ],
        [
            _bbLiquidationModule.address,
            _bbBorrow.address,
            _bbCollateral.address,
            _bbLeverage.address,
            bar.address,
            collateral.address,
            collateralId,
            oracle.address,
            exchangeRatePrecision,
            debtRateAgainstEth,
            debtRateMin,
            debtRateMax,
            debtStartPoint,
            0,
            0,
            ethers.constants.AddressZero,
        ],
    );

    await (await bar.registerBigBang(mediumRiskBigBangMC, data, true)).wait();
    log('BigBang market registered on Penrose', staging);

    const bigBangMarket = new ethers.Contract(
        await bar.clonesOf(
            mediumRiskBigBangMC,
            (await bar.clonesOfCount(mediumRiskBigBangMC)).sub(1),
        ),
        BigBangArtifact.abi,
        ethers.provider,
    ).connect(deployer) as BigBang;

    const OracleMock = new OracleMock__factory(deployer);
    log('Deploying USDOUSDC mock oracle', staging);
    const usdoUsdcOracle = await OracleMock.deploy(
        'USDOUSDCOracle',
        'USDOUSDCOracle',
        ethers.utils.parseEther('1'),
    );
    await usdoUsdcOracle.deployed();
    await usdoUsdcOracle.set(ethers.utils.parseEther('1'));

    const setAssetOracleFn = bigBangMarket.interface.encodeFunctionData(
        'setMarketConfig',
        [
            usdoUsdcOracle.address,
            '0x',
            hre.ethers.constants.AddressZero,
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
        [bigBangMarket.address],
        [setAssetOracleFn],
        true,
    );

    return { bigBangMarket };
}

const log = (message: string, staging?: boolean) =>
    staging && console.log(message);
export async function register(staging?: boolean) {
    const deployer = (await ethers.getSigners())[0];
    const eoas = await ethers.getSigners();
    eoas.shift(); //remove deployer
    hre.tracer.nameTags[deployer.address] = 'deployer';

    const INITIAL_TIMESTAMP = (await hre.ethers.provider.getBlock('latest'))
        .timestamp;

    const eoa1 = new ethers.Wallet(
        ethers.Wallet.createRandom().privateKey,
        ethers.provider,
    );
    hre.tracer.nameTags[eoa1.address] = 'eoa1';

    if (!staging) {
        await setBalance(eoa1.address, 100000);
    }

    // ------------------- Deploy WethUSDC mock oracle -------------------
    log('Deploying WethUSDC mock oracle', staging);
    const OracleMock = new OracleMock__factory(deployer);
    const wethUsdcOracle = await OracleMock.deploy(
        'WETHMOracle',
        'WETHMOracle',
        (1e18).toString(),
    );

    log(
        `Deployed WethUSDC mock oracle ${wethUsdcOracle.address} with no arguments `,
        staging,
    );
    await (await wethUsdcOracle.set(__wethUsdcPrice)).wait();
    await verifyEtherscan(wethUsdcOracle.address, [], staging);
    log('Price was set for WethUSDC mock oracle ', staging);

    // -------------------  Deploy WethUSD0 mock oracle -------------------
    log('Deploying USD0WETH mock oracle', staging);
    const usd0WethOracle = await OracleMock.deploy(
        'USD0Oracle',
        'USD0Oracle',
        (1e18).toString(),
    );
    log(
        `Deployed USD0WETH mock oracle ${usd0WethOracle.address} with no arguments`,
        staging,
    );
    const __usd0WethPrice = __wethUsdcPrice.div(1000000);
    await (await usd0WethOracle.set(__usd0WethPrice)).wait();
    await verifyEtherscan(usd0WethOracle.address, [], staging);
    log('Price was set for USD0WETH mock oracle', staging);

    // ------------------- 1  Deploy tokens -------------------
    log('Deploying Tokens', staging);
    const { usdc, weth, tap } = await registerERC20Tokens(deployer, staging);
    log(
        `Deployed Tokens ${tap.address}, ${usdc.address}, ${weth.address}`,
        staging,
    );

    // -------------------  2 Deploy Yieldbox -------------------
    log('Deploying YieldBox', staging);
    const { yieldBox, uriBuilder } = await registerYieldBox(deployer, staging);
    log(`Deployed YieldBox ${yieldBox.address}`, staging);

    // ------------------- 2.1 Create Cluster -------------------
    const LZEndpointMock = new LZEndpointMock__factory(deployer);
    const clusterLzEndpoint = await LZEndpointMock.deploy(
        await hre.getChainId(),
    );
    const cluster = await (
        await ethers.getContractFactory('Cluster')
    ).deploy(await hre.getChainId(), deployer.address);
    await cluster.deployed();
    log(`Deployed Cluster ${cluster.address} with args [1]`, staging);

    await cluster.updateContract(0, yieldBox.address, true);

    // ------------------- 2.2 Deploy Penrose -------------------
    log('Deploying Penrose', staging);

    const { bar } = await registerPenrose(
        deployer,
        yieldBox.address,
        cluster.address,
        tap.address,
        weth.address,
        staging,
    );
    log(`Deployed Penrose ${bar.address}`, staging);

    // -------------------  3 Add asset types to Penrose -------------------
    log('Setting Penrose assets', staging);
    const { usdcAssetId, wethAssetId, usdcStrategy } = await setPenroseAssets(
        deployer,
        yieldBox,
        bar,
        usdc.address,
    );
    log(
        `Penrose assets were set USDC: ${usdcAssetId}, WETH: ${wethAssetId}`,
        staging,
    );

    // ------------------- 6 Deploy MediumRisk master contract -------------------
    log('Deploying MediumRiskMC', staging);
    const { mediumRiskMC } = await deployMediumRiskMC(deployer, bar, staging);
    log(`Deployed MediumRiskMC ${mediumRiskMC.address}`, staging);

    // ------------------- 6.1 Deploy MediumRiskBigBang master contract -------------------
    log('Deploying MediumRiskBigBangMC', staging);
    const { mediumRiskBigBangMC } = await deployMediumRiskBigBangMC(
        deployer,
        bar,
        staging,
    );
    log(`Deployed MediumRiskBigBangMC ${mediumRiskBigBangMC.address}`, staging);

    // ------------------- 7 Deploy WethUSDC medium risk MC clone-------------------
    log('Deploying WethUsdcSingularity', staging);
    const wethUsdcSingularityData = await registerSingularity(
        deployer,
        mediumRiskMC.address,
        yieldBox,
        bar,
        weth,
        wethAssetId,
        usdc,
        usdcAssetId,
        wethUsdcOracle,
        ethers.utils.parseEther('1'),
        staging,
    );
    const wethUsdcSingularity = wethUsdcSingularityData.singularityMarket;
    await cluster.updateContract(0, wethUsdcSingularity.address, true);
    const SGLCollateral = new SGLCollateral__factory(deployer);
    const _sglCollateralModule = await SGLCollateral.deploy();

    const SGLBorrow = new SGLBorrow__factory(deployer);
    const _sglBorrowModule = await SGLBorrow.deploy();

    const SGLLeverage = new SGLLeverage__factory(deployer);
    const _sglLeverageModule = await SGLLeverage.deploy();

    const _sglLiquidationModule = wethUsdcSingularityData._sglLiquidationModule;
    log(`Deployed WethUsdcSingularity ${wethUsdcSingularity.address}`, staging);

    // ------------------- 10 Deploy USDO -------------------
    log('Registering USDO', staging);
    const chainId = await hre.getChainId();
    const { usd0, lzEndpointContract } = await registerUsd0Contract(
        chainId,
        yieldBox.address,
        cluster.address,
        deployer,
        staging,
    );
    log(`USDO registered ${usd0.address}`, staging);

    // ------------------- 11 Set USDO on Penrose -------------------
    await bar.setUsdoToken(usd0.address);
    log('USDO was set on Penrose', staging);

    // ------------------- 12 Register WETH BigBang -------------------
    log('Deploying WethMinterSingularity', staging);
    const bigBangRegData = await registerBigBangMarket(
        deployer,
        mediumRiskBigBangMC.address,
        yieldBox,
        bar,
        weth,
        wethAssetId,
        usd0WethOracle,
        ethers.utils.parseEther('1'),
        0,
        0,
        0,
        0, //ignored, as this is the main market
        staging,
    );
    const wethBigBangMarket = bigBangRegData.bigBangMarket;
    await bar.setBigBangEthMarket(wethBigBangMarket.address);
    log(`WethMinterSingularity deployed ${wethBigBangMarket.address}`, staging);

    // ------------------- 13 Set Minter and Burner for USDO -------------------
    await usd0.setMinterStatus(wethBigBangMarket.address, true);
    await usd0.setBurnerStatus(wethBigBangMarket.address, true);

    // ------------------- 15 Create Magnetar -------------------
    log('Deploying MagnetarV2', staging);
    const magnetarYieldboxModule = await (
        await (
            await hre.ethers.getContractFactory('MagnetarYieldboxModule')
        ).deploy()
    ).deployed();
    hre.tracer.nameTags[magnetarYieldboxModule.address] =
        'magnetarYieldboxModule';
    const magnetarMarketModule1 = await (
        await (
            await ethers.getContractFactory('MagnetarMarketModule1')
        ).deploy()
    ).deployed();
    hre.tracer.nameTags[magnetarMarketModule1.address] =
        'MagnetarMarketModule1';
    const magnetarMarketModule2 = await (
        await (
            await ethers.getContractFactory('MagnetarMarketModule2')
        ).deploy()
    ).deployed();
    hre.tracer.nameTags[magnetarMarketModule2.address] =
        'MagnetarMarketModule2';

    const magnetar = await (
        await ethers.getContractFactory('MagnetarV2')
    ).deploy(
        cluster.address,
        deployer.address,
        magnetarMarketModule1.address,
        magnetarMarketModule2.address,
        magnetarYieldboxModule.address,
    );
    await magnetar.deployed();
    log(
        `Deployed MagnetarV2 ${magnetar.address} with args [${deployer.address}]`,
        staging,
    );
    await cluster.updateContract(0, magnetar.address, true);

    const magnetarHelper = await (
        await ethers.getContractFactory('MagnetarHelper')
    ).deploy();
    await magnetarHelper.deployed();
    log(`Deployed MagnetarHelper ${magnetar.address} with no args`, staging);

    if (staging) {
        //------------------- 17 Create CurveStableToUsdoBidder -------------------
        log('Deploying CurveStableToUsdoBidder', staging);
        const { stableToUsdoBidder } = await deployCurveStableToUsdoBidder(
            deployer,
            bar,
            usdc,
            usd0,
            staging,
        );
        log(
            `Deployed CurveStableToUsdoBidder ${stableToUsdoBidder.address}`,
            staging,
        );
        // ------------------- 18 Create WethUsd0Singularity -------------------
        log('Deploying WethUsd0Singularty', staging);
        const usd0AssetId = await yieldBox.ids(
            1,
            usd0.address,
            ethers.constants.AddressZero,
            0,
        );
        const { wethUsdoSingularity } = await createWethUsd0Singularity(
            deployer,
            usd0,
            weth,
            bar,
            usd0AssetId,
            wethAssetId,
            mediumRiskMC,
            yieldBox,
            stableToUsdoBidder,
            ethers.utils.parseEther('1'),
            staging,
        );
        log(
            `Deployed WethUsd0Singularity ${wethUsdoSingularity.address}`,
            staging,
        );
    }

    const timeTravel = async (seconds: number) => {
        await time.increase(seconds);
    };

    if (!staging) {
        await setBalance(eoa1.address, 100000);
    }

    const initialSetup = {
        __wethUsdcPrice,
        __usd0WethPrice,
        deployer,
        eoas,
        usd0,
        lzEndpointContract,
        usdc,
        usdcAssetId,
        weth,
        wethAssetId,
        usdcStrategy,
        tap,
        wethUsdcOracle,
        usd0WethOracle,
        yieldBox,
        bar,
        wethUsdcSingularity,
        wethBigBangMarket,
        _sglLiquidationModule,
        _sglCollateralModule,
        _sglBorrowModule,
        _sglLeverageModule,
        magnetar,
        cluster,
        eoa1,
        mediumRiskMC,
        registerSingularity,
        INITIAL_TIMESTAMP,
        magnetarHelper,
    };

    /**
     * UTIL FUNCS
     */

    const approveTokensAndSetBarApproval = async (account?: typeof eoa1) => {
        const _usdc = account ? usdc.connect(account) : usdc;
        const _weth = account ? weth.connect(account) : weth;
        const _yieldBox = account ? yieldBox.connect(account) : yieldBox;
        await (
            await _usdc.approve(yieldBox.address, ethers.constants.MaxUint256)
        ).wait();
        await (
            await _weth.approve(yieldBox.address, ethers.constants.MaxUint256)
        ).wait();
        await (
            await _yieldBox.setApprovalForAll(wethUsdcSingularity.address, true)
        ).wait();
    };

    const wethDepositAndAddAsset = async (
        amount: BigNumberish,
        account?: typeof eoa1,
    ) => {
        const _account = account ?? deployer;
        const _yieldBox = account ? yieldBox.connect(account) : yieldBox;
        const _wethUsdcSingularity = account
            ? wethUsdcSingularity.connect(account)
            : wethUsdcSingularity;

        const id = await _wethUsdcSingularity.assetId();
        const _valShare = await _yieldBox.toShare(id, amount, false);
        await (
            await _yieldBox.depositAsset(
                id,
                _account.address,
                _account.address,
                0,
                _valShare,
            )
        ).wait();
        await (
            await _wethUsdcSingularity.addAsset(
                _account.address,
                _account.address,
                false,
                _valShare,
            )
        ).wait();
    };

    const usdcDepositAndAddCollateral = async (
        amount: BigNumberish,
        account?: typeof eoa1,
    ) => {
        const _account = account ?? deployer;
        const _yieldBox = account ? yieldBox.connect(account) : yieldBox;
        const _wethUsdcSingularity = account
            ? wethUsdcSingularity.connect(account)
            : wethUsdcSingularity;

        const wethUsdcCollateralId = await _wethUsdcSingularity.collateralId();
        await (
            await _yieldBox.depositAsset(
                wethUsdcCollateralId,
                _account.address,
                _account.address,
                amount,
                0,
            )
        ).wait();
        const _wethUsdcValShare = await _yieldBox.balanceOf(
            _account.address,
            wethUsdcCollateralId,
        );
        await (
            await _wethUsdcSingularity.addCollateral(
                _account.address,
                _account.address,
                false,
                _wethUsdcValShare,
            )
        ).wait();
    };

    const initContracts = async () => {
        const deployerAddress = deployer.address;
        await (await weth.mintTo(deployerAddress, 1000)).wait();

        const mintValShare = await yieldBox.toShare(
            await wethUsdcSingularity.assetId(),
            1000,
            false,
        );
        await (await weth.approve(yieldBox.address, 1000)).wait();
        await (
            await yieldBox.depositAsset(
                await wethUsdcSingularity.assetId(),
                deployer.address,
                deployer.address,
                0,
                mintValShare,
            )
        ).wait();
        await (
            await yieldBox.setApprovalForAll(wethUsdcSingularity.address, true)
        ).wait();
        await (
            await wethUsdcSingularity.addAsset(
                deployer.address,
                deployer.address,
                false,
                mintValShare,
            )
        ).wait();
    };

    const utilFuncs = {
        BN,
        approveTokensAndSetBarApproval,
        wethDepositAndAddAsset,
        usdcDepositAndAddCollateral,
        initContracts,
        timeTravel,
        deployCurveStableToUsdoBidder,
        registerUsd0Contract,
        createWethUsd0Singularity,
        createTokenEmptyStrategy,
    };

    return { ...initialSetup, ...utilFuncs, verifyEtherscanQueue };
}

export async function registerFork() {
    let binanceWallet;
    await impersonateAccount(process.env.BINANCE_WALLET_ADDRESS!);
    // eslint-disable-next-line prefer-const
    binanceWallet = await ethers.getSigner(process.env.BINANCE_WALLET_ADDRESS!);

    const deployer = (await ethers.getSigners())[0];

    const usdcAddress = process.env.USDC!;
    const usdtAddress = process.env.USDT!;
    const wethAddress = process.env.WETH!;

    const usdc = await ethers.getContractAt(
        '@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20',
        usdcAddress,
    );
    const usdt = await ethers.getContractAt(
        '@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20',
        usdtAddress,
    );
    const weth = await ethers.getContractAt(
        '@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20',
        wethAddress,
    );

    const YieldBoxURIBuilder = new YieldBoxURIBuilder__factory(deployer);
    const YieldBox = new YieldBox__factory(deployer);
    const uriBuilder = await YieldBoxURIBuilder.deploy();
    const yieldBox = await YieldBox.deploy(
        ethers.constants.AddressZero,
        uriBuilder.address,
    );

    const wethStrategy = await createTokenEmptyStrategy(
        deployer,
        yieldBox.address,
        wethAddress,
    );
    console.log('--------------------------------------A');
    await yieldBox.registerAsset(1, wethAddress, wethStrategy.address, 0);
    const wethAssetId = await yieldBox.ids(
        1,
        wethAddress,
        wethStrategy.address,
        0,
    );

    const usdcStrategy = await createTokenEmptyStrategy(
        deployer,
        yieldBox.address,
        usdcAddress,
    );
    console.log('--------------------------------------B');
    await yieldBox.registerAsset(1, usdcAddress, usdcStrategy.address, 0);
    const usdcAssetId = await yieldBox.ids(
        1,
        usdcAddress,
        usdcStrategy.address,
        0,
    );

    const usdtStrategy = await createTokenEmptyStrategy(
        deployer,
        yieldBox.address,
        usdtAddress,
    );
    console.log('--------------------------------------C');
    await yieldBox.registerAsset(1, usdtAddress, usdtStrategy.address, 0);
    const usdtAssetId = await yieldBox.ids(
        1,
        usdtAddress,
        usdtStrategy.address,
        0,
    );

    const router = process.env.UniswapV2Router02!;
    const factory = process.env.UniswapV2Factory!;
    const uniswapV2Swapper = await (
        await ethers.getContractFactory('UniswapV2Swapper')
    ).deploy(router, factory, yieldBox.address, deployer.address);
    await uniswapV2Swapper.deployed();

    const routerV3 = process.env.UniswapV3Router!;
    const factoryV3 = process.env.UniswapV3Factory!;
    const uniswapV3Swapper = await (
        await ethers.getContractFactory('UniswapV3Swapper')
    ).deploy(yieldBox.address, routerV3, factoryV3, deployer.address);
    await uniswapV3Swapper.deployed();

    const curve3Pool = process.env.Curve3Pool!;
    const curveSwapper = await (
        await ethers.getContractFactory('CurveSwapper')
    ).deploy(curve3Pool, yieldBox.address);
    await curveSwapper.deployed();

    return {
        weth,
        usdc,
        usdt,
        wethAssetId,
        usdcAssetId,
        usdtAssetId,
        deployer,
        binanceWallet,
        yieldBox,
        uniswapV2Swapper,
        uniswapV3Swapper,
        curveSwapper,
        createSimpleSwapData,
        createYbSwapData,
    };
}

export async function getSGLPermitSignature(
    type: 'Permit' | 'PermitBorrow',
    wallet: Wallet | SignerWithAddress,
    token: Singularity,
    spender: string,
    value: BigNumberish = ethers.constants.MaxUint256,
    deadline = ethers.constants.MaxUint256,
    permitConfig?: {
        nonce?: BigNumberish;
        name?: string;
        chainId?: number;
        version?: string;
    },
): Promise<Signature> {
    const [nonce, _, version, chainId] = await Promise.all([
        permitConfig?.nonce ?? token.nonces(wallet.address),
        permitConfig?.name ?? token.name(),
        permitConfig?.version ?? '1',
        permitConfig?.chainId ?? wallet.getChainId(),
    ]);

    const permit = [
        {
            name: 'owner',
            type: 'address',
        },
        {
            name: 'spender',
            type: 'address',
        },
        {
            name: 'value',
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

    return splitSignature(
        await wallet._signTypedData(
            {
                name: 'Tapioca Singularity',
                version,
                chainId,
                verifyingContract: token.address,
            },
            type === 'Permit' ? { Permit: permit } : { PermitBorrow: permit },
            {
                owner: wallet.address,
                spender,
                value,
                nonce,
                deadline,
            },
        ),
    );
}

const createYbSwapData = (
    token1Id: BigNumberish,
    token2Id: BigNumberish,
    shareIn: BigNumberish,
    shareOut: BigNumberish,
) => {
    const swapData = {
        tokensData: {
            tokenIn: ethers.constants.AddressZero,
            tokenInId: token1Id,
            tokenOut: ethers.constants.AddressZero,
            tokenOutId: token2Id,
        },
        amountData: {
            amountIn: 0,
            amountOut: 0,
            shareIn: shareIn,
            shareOut: shareOut,
        },
        yieldBoxData: {
            withdrawFromYb: true,
            depositToYb: true,
        },
    };

    return swapData;
};

const createSimpleSwapData = (
    token1: string,
    token2: string,
    amountIn: BigNumberish,
    amountOut: BigNumberish,
) => {
    const swapData = {
        tokensData: {
            tokenIn: token1,
            tokenInId: 0,
            tokenOut: token2,
            tokenOutId: 0,
        },
        amountData: {
            amountIn: amountIn,
            amountOut: amountOut,
            shareIn: 0,
            shareOut: 0,
        },
        yieldBoxData: {
            withdrawFromYb: false,
            depositToYb: false,
        },
    };

    return swapData;
};
