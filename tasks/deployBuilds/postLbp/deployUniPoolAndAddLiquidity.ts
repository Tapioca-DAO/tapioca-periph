import { ERC20Mock, IArrakisV2Vault, TapiocaMulticall } from '@typechain/index';
import { FeeAmount, encodeSqrtRatioX96 } from '@uniswap/v3-sdk';
import { BigNumberish } from 'ethers';
import {
    DeployerVM,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';
import { uniPoolInfo__task } from 'tasks/exec/misc/uniPoolInfo';
import { deployUniV3Pool } from './deployUniV3Pool';
import { saveBuildLocally } from '@tapioca-sdk/api/db';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { arrakis } from '@typechain/contracts/interfaces/external';

export async function deployUniPoolAndAddLiquidity(
    params: TTapiocaDeployerVmPass<{
        tokenToInitArrakisShares: string;
        deploymentName: string;
        arrakisDeploymentName: string;
        tokenA: string;
        tokenB: string;
        ratioTokenA: number;
        ratioTokenB: number;
        amountTokenA: BigNumberish;
        amountTokenB: BigNumberish;
        feeAmount: FeeAmount;
        options?: {
            mintMock?: boolean;
            arrakisDepositLiquidity?: boolean;
        };
    }>,
) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, isTestnet } = params;
    const {
        tag,
        tokenToInitArrakisShares,
        deploymentName,
        arrakisDeploymentName,
        tokenA,
        tokenB,
        ratioTokenA,
        ratioTokenB,
        amountTokenA,
        amountTokenB,
        feeAmount,
        options,
    } = taskArgs;
    const owner = tapiocaMulticallAddr;

    const {
        computedPoolAddress,
        ratio0,
        ratio1,
        token0,
        token1,
        amount0,
        amount1,
    } = await deployUniV3Pool(
        hre,
        tag,
        deploymentName,
        tokenA,
        tokenB,
        ratioTokenA,
        ratioTokenB,
        amountTokenA,
        amountTokenB,
        feeAmount,
    );
    const token0Erc20 = await hre.ethers.getContractAt('ERC20Mock', token0); // ERC20Mock is used just for the interface
    const token1Erc20 = await hre.ethers.getContractAt('ERC20Mock', token1);

    await uniPoolInfo__task({ poolAddr: computedPoolAddress }, hre);

    const arrakisFactory = await hre.ethers.getContractAt(
        'IArrakisV2Factory',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.ARRAKIS_FACTORY,
    );
    await (
        await arrakisFactory.deployVault(
            {
                feeTiers: [feeAmount],
                token0,
                token1,
                init0:
                    token0.toLowerCase() ==
                    tokenToInitArrakisShares.toLowerCase()
                        ? hre.ethers.utils.parseEther('1')
                        : 0,
                init1:
                    token1.toLowerCase() ==
                    tokenToInitArrakisShares.toLowerCase()
                        ? hre.ethers.utils.parseEther('1')
                        : 0,
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

    const arrakisVault = await hre.ethers.getContractAt(
        'IArrakisV2Vault',
        vaultAddr,
    );
    console.log(
        `[+] Arrakis vault [${await arrakisVault.name()}] deployed at: [${vaultAddr}]`,
    );
    saveBuildLocally(
        {
            chainId: hre.SDK.eChainId,
            chainIdName: hre.SDK.chainInfo.name,
            contracts: [
                {
                    address: vaultAddr,
                    name: arrakisDeploymentName,
                    meta: {
                        vaultNum: numVaults.toNumber() - 1,
                    },
                },
            ],
            lastBlockHeight: await hre.ethers.provider.getBlockNumber(),
        },
        tag,
    );

    console.log('[+] Deposit liquidity in pool');
    const arrakisResolve = await hre.ethers.getContractAt(
        'IArrakisResolver',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.ARRAKIS_RESOLVER,
    );

    // Mint tokens for liquidity if one of them is missing
    if (isTestnet && options?.mintMock) {
        console.log('[+] TESTNET: Minting tokens for liquidity');
        // await token0.mintTo(owner, (1e18).toString());
        // await token1.mintTo(owner, (1e18).toString());
        const calls: TapiocaMulticall.CallStruct[] = [];
        if ((await token0Erc20.balanceOf(owner)).isZero()) {
            console.log(
                '[+] Minting missing balance for',
                await token0Erc20.name(),
                '. Minting...',
            );
            calls.push({
                target: token0,
                callData: token0Erc20.interface.encodeFunctionData('mintTo', [
                    owner,
                    amount0,
                ]),
                allowFailure: false,
            });
        }
        if ((await token1Erc20.balanceOf(owner)).isZero()) {
            console.log(
                '[+] Minting missing balance for',
                await token1Erc20.name(),
                '. Minting...',
            );
            calls.push({
                target: token1,
                callData: token1Erc20.interface.encodeFunctionData('mintTo', [
                    owner,
                    amount1,
                ]),
                allowFailure: false,
            });
        }
        if (calls.length > 0) {
            await VM.executeMulticall(calls);
        }
    }

    const uniPool = await hre.ethers.getContractAt(
        'IUniswapV3Pool',
        computedPoolAddress,
    );

    // Mint Arrakis liquidity
    console.log(options?.arrakisDepositLiquidity);
    if (options?.arrakisDepositLiquidity) {
        const slot0 = await uniPool.slot0();
        const tickSpacing = await uniPool.tickSpacing();
        const lowerTick = slot0.tick - (slot0.tick % tickSpacing) - tickSpacing;
        const upperTick =
            slot0.tick - (slot0.tick % tickSpacing) + 2 * tickSpacing;

        await restrictMintAndArrakisMint({
            hre,
            amount0: amount0,
            amount1: amount1,
            to: owner,
            arrakisVault,
            token0: token0Erc20,
            token1: token1Erc20,
            tokenToInitArrakisShares,
            VM,
        });

        console.log('[+] Arrakis shares:', await arrakisVault.balanceOf(owner));
        console.log('[+] Total supply:', await arrakisVault.totalSupply());

        // const slot0 = await uniPool.slot0();
        // const tickSpacing = await uniPool.tickSpacing();
        // const lowerTick =
        //     slot0.tick - (slot0.tick % tickSpacing) - tickSpacing;
        // const upperTick =
        //     slot0.tick - (slot0.tick % tickSpacing) + 2 * tickSpacing;
        // console.log(lowerTick, upperTick);

        const rebalanceParams = await arrakisResolve.standardRebalance(
            [
                {
                    range: {
                        lowerTick: -887200,
                        upperTick: 887200,
                        feeTier: feeAmount,
                    },
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

async function restrictMintAndArrakisMint(params: {
    hre: HardhatRuntimeEnvironment;
    tokenToInitArrakisShares: string;
    token0: ERC20Mock;
    token1: ERC20Mock;
    arrakisVault: IArrakisV2Vault;
    amount0: BigNumberish;
    amount1: BigNumberish;
    to: string;
    VM: DeployerVM;
}) {
    const {
        hre,
        tokenToInitArrakisShares,
        token0,
        token1,
        arrakisVault,
        amount0,
        amount1,
        to: owner,
        VM,
    } = params;

    const initShares = hre.ethers.utils.parseEther('1');
    console.log('[+] Minting Arrakis shares:', initShares.toString());

    // await token0.approve(arrakisVault.address, amountsForLiquidity.amount0);
    // await token1.approve(arrakisVault.address, amountsForLiquidity.amount1);
    // await arrakisVault.mint(amountsForLiquidity.mintAmount, owner);
    await VM.executeMulticall([
        {
            target: arrakisVault.address,
            callData: arrakisVault.interface.encodeFunctionData(
                'setRestrictedMint',
                [owner],
            ),
            allowFailure: false,
        },
        {
            target: tokenToInitArrakisShares,
            callData: token1.interface.encodeFunctionData('approve', [
                arrakisVault.address,
                initShares,
            ]),
            allowFailure: false,
        },
        {
            target: arrakisVault.address,
            callData: arrakisVault.interface.encodeFunctionData('mint', [
                initShares,
                arrakisVault.address,
            ]),
            allowFailure: false,
        },
        {
            target: token0.address,
            callData: token0.interface.encodeFunctionData('transfer', [
                arrakisVault.address,
                tokenToInitArrakisShares.toLowerCase() ==
                token0.address.toLowerCase()
                    ? hre.ethers.BigNumber.from(amount0).sub(initShares)
                    : amount0,
            ]),
            allowFailure: false,
        },
        {
            target: token1.address,
            callData: token1.interface.encodeFunctionData('transfer', [
                arrakisVault.address,
                token1.address.toLowerCase()
                    ? hre.ethers.BigNumber.from(amount1).sub(initShares)
                    : amount1,
            ]),
            allowFailure: false,
        },
    ]);
}
