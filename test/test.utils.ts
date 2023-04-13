import { time } from '@nomicfoundation/hardhat-network-helpers';
import { BigNumber, BigNumberish } from 'ethers';
import hre, { ethers } from 'hardhat';
import SingularityArtifact from '../gitsub_tapioca-sdk/src/artifacts/tapioca-bar/contracts/singularity/Singularity.sol/Singularity.json';

import {
    YieldBox__factory,
    YieldBoxURIBuilder__factory,
    ERC20WithoutStrategy__factory,
    YieldBox,
} from '../gitsub_tapioca-sdk/src/typechain/YieldBox';
import {
    Singularity,
    Penrose,
    Penrose__factory,
    Singularity__factory,
    SGLLiquidation__factory,
    SGLLendingBorrowing__factory,
    LiquidationQueue__factory,
    USDO,
    MarketsHelper__factory,
    UniUsdoToWethBidder__factory,
    CurveStableToUsdoBidder__factory,
    ProxyDeployer__factory,
    USDO__factory,
    CurveStableToUsdoBidder,
} from '../gitsub_tapioca-sdk/src/typechain/Tapioca-bar';

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
} from '../gitsub_tapioca-sdk/src/typechain/tapioca-mocks';
import {
    CurveSwapper__factory,
    MultiSwapper,
    MultiSwapper__factory,
} from '../typechain';

ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR);
const verifyEtherscanQueue: { address: string; args: any[] }[] = [];

async function resetVM() {
    await ethers.provider.send('hardhat_reset', []);
}

export function BN(n: BigNumberish) {
    return ethers.BigNumber.from(n.toString());
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
    tapAddress: string,
    wethAddress: string,
    staging?: boolean,
) {
    const Penrose = new Penrose__factory(deployer);

    const bar = await Penrose.deploy(
        yieldBox,
        tapAddress,
        wethAddress,
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
    const wethAssetId = await bar.wethAssetId();

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
    await (await weth.freeMint(wethPairAmount)).wait();
    await (await usdc.freeMint(usdcPairAmount)).wait();

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
    await time.increase(86500);

    // Create WETH/TAP LP
    await (await weth.freeMint(wethPairAmount)).wait();
    await (await tap.freeMint(wethPairAmount)).wait();

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

    await time.increase(86500);
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

async function registerMultiSwapper(
    deployer: any,
    bar: Penrose,
    __uniFactoryAddress: string,
    __uniFactoryPairCodeHash: string,
    staging?: boolean,
) {
    const MultiSwapper = new MultiSwapper__factory(deployer);
    const multiSwapper = await MultiSwapper.deploy(
        __uniFactoryAddress,
        bar.address,
        __uniFactoryPairCodeHash,
    );
    log(
        `Deployed MultiSwapper ${multiSwapper.address} with args [${__uniFactoryAddress}, ${bar.address}, ${__uniFactoryPairCodeHash}]`,
        staging,
    );

    await (await bar.setSwapper(multiSwapper.address, true)).wait();
    log('Swapper was set on Penrose', staging);

    await verifyEtherscan(
        multiSwapper.address,
        [__uniFactoryAddress, bar.address, __uniFactoryPairCodeHash],
        staging,
    );

    return { multiSwapper };
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

    const SGLLendingBorrowing = new SGLLendingBorrowing__factory(deployer);
    const _sglLendingBorrowingModule = await SGLLendingBorrowing.deploy();
    log(
        `Deployed WethUsdcSGLLendingBorrowing ${_sglLendingBorrowingModule.address} with no arguments`,
        staging,
    );

    const data = new ethers.utils.AbiCoder().encode(
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
            weth.address,
            wethAssetId,
            usdc.address,
            usdcAssetId,
            wethUsdcOracle.address,
            exchangeRatePrecision ?? 0,
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
    );

    await verifyEtherscan(singularityMarket.address, [], staging);

    return {
        singularityMarket,
        _sglLiquidationModule,
        _sglLendingBorrowingModule,
    };
}

async function registerLiquidationQueue(
    deployer: any,
    bar: Penrose,
    singularity: Singularity,
    feeCollector: string,
    staging?: boolean,
) {
    const LiquidationQueue = new LiquidationQueue__factory(deployer);
    const liquidationQueue = await LiquidationQueue.deploy();
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
        'setLiquidationQueue',
        [liquidationQueue.address],
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

    const USDO = new USDO__factory(owner);
    const usd0 = await USDO.deploy(
        lzEndpointContract.address,
        yieldBox,
        owner.address,
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
    token1: any,
    token2: any,
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
    if (token1.freeMint !== undefined) {
        await token1.freeMint(token1Amount);
    } else {
        await token1.mint(deployerAddress, token1Amount);
    }
    if (token2.freeMint !== undefined) {
        await token2.freeMint(token2Amount);
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
    await time.increase(86500);
}

async function addUniV2UsdoWethLiquidity(
    deployerAddress: string,
    usdo: ERC20Mock,
    weth: ERC20Mock,
    __uniFactory: UniswapV2Factory,
    __uniRouter: UniswapV2Router02,
) {
    const wethPairAmount = ethers.BigNumber.from(1e6).mul((1e18).toString());
    const usdoPairAmount = wethPairAmount.mul(
        __wethUsdcPrice.div((1e18).toString()),
    );
    await addUniV2Liquidity(
        deployerAddress,
        weth,
        usdo,
        wethPairAmount,
        usdoPairAmount,
        __uniFactory,
        __uniRouter,
    );
}

async function createUniV2Usd0Pairs(
    deployerAddress: string,
    uniFactory: UniswapV2Factory,
    uniRouter: UniswapV2Router02,
    weth: ERC20Mock,
    tap: ERC20Mock,
    usdo: USDO,
) {
    // Create WETH<>USDO pair
    const wethPairAmount = ethers.BigNumber.from(1e6).mul((1e18).toString());
    const usdoPairAmount = wethPairAmount.mul(
        __wethUsdcPrice.div((1e18).toString()),
    );
    await addUniV2Liquidity(
        deployerAddress,
        weth,
        usdo,
        wethPairAmount,
        usdoPairAmount,
        uniFactory,
        uniRouter,
        true,
    );

    const __wethUsdoMockPair = await uniFactory.getPair(
        weth.address,
        usdo.address,
    );

    // Create TAP<>USDO pair
    const tapPairAmount = ethers.BigNumber.from(1e6).mul((1e18).toString());
    const usdoTapPairAmount = ethers.BigNumber.from(1e6).mul((1e18).toString());

    await addUniV2Liquidity(
        deployerAddress,
        tap,
        usdo,
        tapPairAmount,
        usdoTapPairAmount,
        uniFactory,
        uniRouter,
        true,
    );

    const __tapUsdoMockPair = await uniFactory.getPair(
        tap.address,
        usdo.address,
    );

    return { __wethUsdoMockPair, __tapUsdoMockPair };
}

async function registerUniUsdoToWethBidder(
    deployer: any,
    uniSwapper: MultiSwapper,
    wethAssetId: BigNumber,
    staging?: boolean,
) {
    const UniUsdoToWethBidder = new UniUsdoToWethBidder__factory(deployer);
    const usdoToWethBidder = await UniUsdoToWethBidder.deploy(
        uniSwapper.address,
        wethAssetId,
    );
    log(
        `Deployed UniUsdoToWethBidder ${usdoToWethBidder.address} with args [${uniSwapper.address},${wethAssetId}]`,
        staging,
    );

    await verifyEtherscan(
        usdoToWethBidder.address,
        [uniSwapper.address, wethAssetId],
        staging,
    );

    return { usdoToWethBidder };
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

    const CurveStableToUsdoBidder = new CurveStableToUsdoBidder__factory(deployer);
    const stableToUsdoBidder = await CurveStableToUsdoBidder.deploy(
        curveSwapper.address,
        2,
    );
    log(
        `Deployed CurveStableToUsdoBidder ${stableToUsdoBidder.address} with args [${curveSwapper.address},2]`,
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
    await verifyEtherscan(
        stableToUsdoBidder.address,
        [curveSwapper.address, 2],
        staging,
    );

    return { stableToUsdoBidder, curveSwapper };
}

async function deployProxyDeployer(deployer: any) {
    const ProxyDeployer = new ProxyDeployer__factory(deployer);
    const proxyDeployer = await ProxyDeployer.deploy();

    return { proxyDeployer };
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

    const SGLLendingBorrowing = new SGLLendingBorrowing__factory(deployer);
    const _sglLendingBorrowingModule = await SGLLendingBorrowing.deploy();
    log(
        `Deployed WethUsd0SGLLendingBorrowingModule ${_sglLendingBorrowingModule.address} with no arguments`,
        staging,
    );

    const collateralSwapPath = [usd0.address, weth.address];

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
            wethUsd0Oracle.address,
            exchangePrecision,
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
    );
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

    const LiquidationQueue = new LiquidationQueue__factory(deployer);
    const liquidationQueue = await LiquidationQueue.deploy();
    log(
        `Deployed WethUsd0LiquidationQueue at ${liquidationQueue.address} with no arguments`,
        staging,
    );

    const feeCollector = new ethers.Wallet(
        ethers.Wallet.createRandom().privateKey,
        ethers.provider,
    );
    log(`WethUsd0Singularity feeCollector ${feeCollector.address}`, staging);

    const LQ_META = {
        activationTime: 600, // 10min
        minBidAmount: ethers.BigNumber.from((1e18).toString()).mul(1), // 1 USDC
        closeToMinBidAmount: ethers.BigNumber.from((1e18).toString()).mul(202),
        defaultBidAmount: ethers.BigNumber.from((1e18).toString()).mul(400), // 400 USDC
        feeCollector: feeCollector.address,
        bidExecutionSwapper: ethers.constants.AddressZero,
        usdoSwapper: stableToUsdoBidder.address,
    };

    await liquidationQueue.init(LQ_META, wethUsdoSingularity.address);
    log('LiquidationQueue initialized');

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
    log('WethUsd0LiquidationQueue was set for WethUsd0Singularity', staging);

    return { wethUsdoSingularity };
}

const log = (message: string, staging?: boolean) =>
    staging && console.log(message);
export async function register(staging?: boolean) {
    if (!staging) {
        await resetVM();
    }

    const deployer = (await ethers.getSigners())[0];
    const eoas = await ethers.getSigners();
    eoas.shift(); //remove deployer

    const eoa1 = new ethers.Wallet(
        ethers.Wallet.createRandom().privateKey,
        ethers.provider,
    );

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

    // ------------------- 2.1 Deploy Penrose -------------------
    log('Deploying Penrose', staging);
    const { bar } = await registerPenrose(
        deployer,
        yieldBox.address,
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

    // -------------------  4 Deploy UNIV2 env -------------------
    log('Deploying UNIV2 Environment', staging);
    const { __wethUsdcMockPair, __wethTapMockPair, __uniFactory, __uniRouter } =
        await uniV2EnvironnementSetup(deployer, weth, usdc, tap, staging);
    log(
        `Deployed UNIV2 Environment WethUsdcMockPair: ${__wethUsdcMockPair}, WethTapMockPar: ${__wethTapMockPair}, UniswapV2Factory: ${__uniFactory.address}, UniswapV2Router02: ${__uniRouter.address}`,
        staging,
    );

    // ------------------- 5 Deploy MultiSwapper -------------------
    log('Registering MultiSwapper', staging);
    const { multiSwapper } = await registerMultiSwapper(
        deployer,
        bar,
        __uniFactory.address,
        await __uniFactory.pairCodeHash(),
        staging,
    );
    log(`Deployed MultiSwapper ${multiSwapper.address}`, staging);

    // ------------------- 6 Deploy MediumRisk master contract -------------------
    log('Deploying MediumRiskMC', staging);
    const { mediumRiskMC } = await deployMediumRiskMC(deployer, bar, staging);
    log(`Deployed MediumRiskMC ${mediumRiskMC.address}`, staging);

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
    const _sglLendingBorrowingModule =
        wethUsdcSingularityData._sglLendingBorrowingModule;
    const _sglLiquidationModule = wethUsdcSingularityData._sglLiquidationModule;
    log(`Deployed WethUsdcSingularity ${wethUsdcSingularity.address}`, staging);

    // ------------------- 8 Set feeTo -------------------
    log('Setting feeTo and feeVeTap', staging);
    const singularityFeeTo = ethers.Wallet.createRandom();
    await bar.setFeeTo(singularityFeeTo.address);
    log(`feeTo ${singularityFeeTo} were set for WethUsdcSingularity`, staging);

    // ------------------- 9 Deploy & set LiquidationQueue -------------------
    log('Registering WETHUSDC LiquidationQueue', staging);
    const feeCollector = new ethers.Wallet(
        ethers.Wallet.createRandom().privateKey,
        ethers.provider,
    );
    const { liquidationQueue, LQ_META } = await registerLiquidationQueue(
        deployer,
        bar,
        wethUsdcSingularity,
        feeCollector.address,
        staging,
    );
    log(
        `Registered WETHUSDC LiquidationQueue ${liquidationQueue.address}`,
        staging,
    );

    // ------------------- 10 Deploy USDO -------------------
    log('Registering USDO', staging);
    const chainId = await hre.getChainId();
    const { usd0, lzEndpointContract } = await registerUsd0Contract(
        chainId,
        yieldBox.address,
        deployer,
        staging,
    );
    log(`USDO registered ${usd0.address}`, staging);

    // ------------------- 11 Set USDO on Penrose -------------------
    await bar.setUsdoToken(usd0.address);
    log('USDO was set on Penrose', staging);

    // ------------------- 14 Create weth-usd0 pair -------------------
    log('Creating WethUSDO and TapUSDO pairs', staging);
    const { __wethUsdoMockPair, __tapUsdoMockPair } =
        await createUniV2Usd0Pairs(
            deployer.address,
            __uniFactory,
            __uniRouter,
            weth,
            tap,
            usd0,
        );
    log(
        `WethUSDO ${__wethUsdoMockPair} & TapUSDO ${__tapUsdoMockPair} pairs created`,
        staging,
    );

    // ------------------- 15 Create MarketsHelper -------------------
    log('Deploying MarketsHelper', staging);
    const MarketsHelper = new MarketsHelper__factory(deployer);
    const marketsHelper = await MarketsHelper.deploy();
    log(
        `Deployed MarketsHelper ${marketsHelper.address} with no args`,
        staging,
    );

    // ------------------- 16 Create UniswapUsdoToWethBidder -------------------
    log('Deploying UniswapUsdoToWethBidder', staging);
    const { usdoToWethBidder } = await registerUniUsdoToWethBidder(
        deployer,
        multiSwapper,
        wethAssetId,
        staging,
    );
    log(
        `Deployed UniswapUsdoToWethBidder ${usdoToWethBidder.address}`,
        staging,
    );

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

    // ------------------- 19 Create ProxyDeployer -------------------
    const { proxyDeployer } = await deployProxyDeployer(deployer);

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
        _sglLiquidationModule,
        _sglLendingBorrowingModule,
        marketsHelper,
        eoa1,
        multiSwapper,
        singularityFeeTo,
        liquidationQueue,
        LQ_META,
        feeCollector,
        usdoToWethBidder,
        mediumRiskMC,
        proxyDeployer,
        registerSingularity,
        __uniFactory,
        __uniRouter,
        __wethUsdcMockPair,
        __wethTapMockPair,
        __wethUsdoMockPair,
        __tapUsdoMockPair,
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
        await (await weth.freeMint(1000)).wait();
        await timeTravel(86500);
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
        addUniV2UsdoWethLiquidity,
        createWethUsd0Singularity,
        createTokenEmptyStrategy,
    };

    return { ...initialSetup, ...utilFuncs, verifyEtherscanQueue };
}
