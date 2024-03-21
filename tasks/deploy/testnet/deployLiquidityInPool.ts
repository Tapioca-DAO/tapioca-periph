import { ERC20Mock, IArrakisV2Vault } from '@typechain/index';
import { FeeAmount } from '@uniswap/v3-sdk';
import { BigNumberish } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployUniV3pool__task, loadLocalContract } from 'tapioca-sdk';
import {
    DeployerVM,
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildERC20Mock } from 'tasks/deployBuilds/mock/buildERC20Mock';
import { uniPoolInfo__task } from 'tasks/exec/misc/uniPoolInfo';
import { DEPLOY_CONFIG } from '../DEPLOY_CONFIG';

const MOCK_TAP = 'TMP_TAP_MOCK_ERC20_0';
const MOCK_USDC = 'TMP_USDC_MOCK_ERC20_1';

export const testnet__deployLiquidityInPool__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre },
        tapiocaDeployTask,
        tapiocaSetupTask,
    );
};

async function tapiocaDeployTask(params: TTapiocaDeployerVmPass<object>) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, isTestnet } = params;
    const { tag } = taskArgs;
    const owner = tapiocaMulticallAddr;

    VM.add(
        await buildERC20Mock(hre, {
            deploymentName: MOCK_TAP,
            args: [MOCK_TAP, MOCK_TAP, (1e18).toString(), 18, owner],
        }),
    );
    VM.add(
        await buildERC20Mock(hre, {
            deploymentName: MOCK_USDC,
            args: [MOCK_USDC, MOCK_USDC, (1e18).toString(), 18, owner],
        }),
    );
}

async function tapiocaSetupTask(params: TTapiocaDeployerVmPass<object>) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, isTestnet } = params;
    const { tag } = taskArgs;
    const owner = tapiocaMulticallAddr;

    let token0 = await hre.ethers.getContractAt(
        'ERC20Mock',
        loadLocalContract(hre, hre.SDK.eChainId, MOCK_TAP, tag).address,
    );
    let token1 = await hre.ethers.getContractAt(
        'ERC20Mock',
        loadLocalContract(hre, hre.SDK.eChainId, MOCK_USDC, tag).address,
    );
    let [ratio0, ratio1] = [33, 10];

    const isToken0Lower = token0.address < token1.address;
    [token0, ratio0, token1, ratio1] = isToken0Lower
        ? [token0, 33, token1, 10]
        : [token1, 10, token0, 33];

    const poolAddr = await deployUniV3pool__task(
        {
            feeTier: FeeAmount.MEDIUM,
            factory: DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.V3_FACTORY,
            positionManager:
                DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!
                    .NONFUNGIBLE_POSITION_MANAGER,
            token0: token0.address,
            token1: token1.address,
            ratio0,
            ratio1,
            tag,
        },
        hre,
    );
    await uniPoolInfo__task({ poolAddr }, hre);

    const arrakisFactory = await hre.ethers.getContractAt(
        'IArrakisV2Factory',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.ARRAKIS_FACTORY,
    );
    await (
        await arrakisFactory.deployVault(
            {
                feeTiers: [FeeAmount.MEDIUM],
                token0: token0.address,
                token1: token1.address,
                init0: ratio0,
                init1: ratio1,
                manager: owner,
                routers: [DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.V3_SWAP_ROUTER],
                owner,
            },
            false,
        )
    ).wait(3);

    const numVaults = await arrakisFactory.numVaults();
    const vaultAddr = (
        await arrakisFactory.vaults(0, await arrakisFactory.numVaults())
    )[numVaults.toNumber() - 1];
    console.log(`[+] Arrakis vault deployed at: ${vaultAddr}`);
    const arrakisVault = await hre.ethers.getContractAt(
        'IArrakisV2Vault',
        vaultAddr,
    );
    console.log('Arrakis vault deployed at:', arrakisVault.address);
    console.log(await arrakisVault.name());

    console.log('[+] Deposit liquidity in pool');
    const arrakisResolve = await hre.ethers.getContractAt(
        'IArrakisResolver',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.ARRAKIS_RESOLVER,
    );

    // Mint tokens for liquidity
    {
        // await token0.mintTo(owner, (1e18).toString());
        // await token1.mintTo(owner, (1e18).toString());
        await VM.executeMulticall([
            {
                target: token0.address,
                callData: token0.interface.encodeFunctionData('mintTo', [
                    owner,
                    (1e18).toString(),
                ]),
                allowFailure: false,
            },
            {
                target: token1.address,
                callData: token1.interface.encodeFunctionData('mintTo', [
                    owner,
                    (1e18).toString(),
                ]),
                allowFailure: false,
            },
        ]);
    }

    // Mint Arrakis liquidity
    {
        const amountsForLiquidity = await arrakisResolve.getMintAmounts(
            arrakisVault.address,
            await token0.balanceOf(owner),
            await token1.balanceOf(owner),
        );

        await arrakisMint({
            amount0: amountsForLiquidity.amount0,
            amount1: amountsForLiquidity.amount1,
            mintAmount: amountsForLiquidity.mintAmount,
            to: owner,
            arrakisVault,
            token0,
            token1,
            VM,
        });

        console.log('[+] Arrakis shares:', await arrakisVault.balanceOf(owner));
        console.log('[+] Total supply:', await arrakisVault.totalSupply());
        console.log(
            '[+] Liquidity deposited in pool:',
            amountsForLiquidity.mintAmount.toString(),
        );
    }
    // Rebalance
    const uniPool = await hre.ethers.getContractAt('IUniswapV3Pool', poolAddr);
    {
        const slot0 = await uniPool.slot0();
        const tickSpacing = await uniPool.tickSpacing();
        const lowerTick = slot0.tick - (slot0.tick % tickSpacing) - tickSpacing;
        const upperTick =
            slot0.tick - (slot0.tick % tickSpacing) + 2 * tickSpacing;
        const rebalanceParams = await arrakisResolve.standardRebalance(
            [
                {
                    range: { lowerTick, upperTick, feeTier: FeeAmount.MEDIUM },
                    weight: 10_000, // 100%
                },
            ],
            arrakisVault.address,
        );
        // await arrakisVault.rebalance(rebalanceParams);
        await VM.executeMulticall([
            {
                target: arrakisVault.address,
                callData: arrakisVault.interface.encodeFunctionData(
                    'rebalance',
                    [rebalanceParams],
                ),
                allowFailure: false,
            },
        ]);
    }

    console.log('[+] UniV3 pool liquidity:', await uniPool.liquidity());
}

async function arrakisMint(params: {
    token0: ERC20Mock;
    token1: ERC20Mock;
    arrakisVault: IArrakisV2Vault;
    amount0: BigNumberish;
    amount1: BigNumberish;
    mintAmount: BigNumberish;
    to: string;
    VM: DeployerVM;
}) {
    const {
        token0,
        token1,
        arrakisVault,
        amount0,
        amount1,
        mintAmount,
        to: owner,
        VM,
    } = params;

    // await token0.approve(arrakisVault.address, amountsForLiquidity.amount0);
    // await token1.approve(arrakisVault.address, amountsForLiquidity.amount1);
    // await arrakisVault.mint(amountsForLiquidity.mintAmount, owner);
    await VM.executeMulticall([
        {
            target: token0.address,
            callData: token0.interface.encodeFunctionData('approve', [
                arrakisVault.address,
                amount0,
            ]),
            allowFailure: false,
        },
        {
            target: token1.address,
            callData: token1.interface.encodeFunctionData('approve', [
                arrakisVault.address,
                amount1,
            ]),
            allowFailure: false,
        },
        {
            target: arrakisVault.address,
            callData: arrakisVault.interface.encodeFunctionData('mint', [
                mintAmount,
                owner,
            ]),
            allowFailure: false,
        },
    ]);
}
