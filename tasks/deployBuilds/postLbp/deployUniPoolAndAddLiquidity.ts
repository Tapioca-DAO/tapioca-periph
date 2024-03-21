import { ERC20Mock, IArrakisV2Vault } from '@typechain/index';
import { FeeAmount } from '@uniswap/v3-sdk';
import { BigNumberish } from 'ethers';
import {
    DeployerVM,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';
import { uniPoolInfo__task } from 'tasks/exec/misc/uniPoolInfo';
import { deployUniV3TapWethPool } from './deployUniV3TapWethPool';

export async function deployUniPoolAndAddLiquidity(
    params: TTapiocaDeployerVmPass<{ ratioTap: number; ratioWeth: number }>,
) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, isTestnet } = params;
    const { tag, ratioTap, ratioWeth } = taskArgs;
    const owner = tapiocaMulticallAddr;

    const { computedPoolAddress, fee, ratio0, ratio1, token0, token1 } =
        await deployUniV3TapWethPool(hre, tag, ratioTap, ratioWeth);
    const token0Erc20 = await hre.ethers.getContractAt('ERC20Mock', token0);
    const token1Erc20 = await hre.ethers.getContractAt('ERC20Mock', token1);

    await uniPoolInfo__task({ poolAddr: computedPoolAddress }, hre);

    const arrakisFactory = await hre.ethers.getContractAt(
        'IArrakisV2Factory',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.ARRAKIS_FACTORY,
    );
    await (
        await arrakisFactory.deployVault(
            {
                feeTiers: [fee],
                token0,
                token1,
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
                target: token0,
                callData: token0Erc20.interface.encodeFunctionData('mintTo', [
                    owner,
                    (1e18).toString(),
                ]),
                allowFailure: false,
            },
            {
                target: token1,
                callData: token0Erc20.interface.encodeFunctionData('mintTo', [
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
            await token0Erc20.balanceOf(owner),
            await token1Erc20.balanceOf(owner),
        );

        await arrakisMint({
            amount0: amountsForLiquidity.amount0,
            amount1: amountsForLiquidity.amount1,
            mintAmount: amountsForLiquidity.mintAmount,
            to: owner,
            arrakisVault,
            token0: token0Erc20,
            token1: token1Erc20,
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
    const uniPool = await hre.ethers.getContractAt(
        'IUniswapV3Pool',
        computedPoolAddress,
    );
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
