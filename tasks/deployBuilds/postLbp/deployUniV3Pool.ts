import { Token } from '@uniswap/sdk-core';
import { FeeAmount, computePoolAddress } from '@uniswap/v3-sdk';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployUniV3pool__task } from 'tapioca-sdk';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

/**
 * @notice Deploys a Uniswap V3 Pool.
 * @returns Address of the deployed pool
 */
export const deployUniV3Pool = async (
    hre: HardhatRuntimeEnvironment,
    tag: string,
    deploymentName: string,
    tokenA: string,
    tokenB: string,
    ratioA: number,
    ratioB: number,
    feeAmount: FeeAmount,
) => {
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });

    /**
     * Load contracts
     */
    const { uniV3Factory, poolInitializer } = await loadContract(hre, tag);
    const [token0, ratio0, token1, ratio1] =
        tokenA < tokenB
            ? [tokenA, ratioA, tokenB, ratioB]
            : [tokenB, ratioB, tokenA, ratioA];

    const computedPoolAddress = computePoolAddress({
        factoryAddress: uniV3Factory.address,
        tokenA: new Token(hre.network.config.chainId!, tokenA, 18),
        tokenB: new Token(hre.network.config.chainId!, tokenB, 18),
        fee: feeAmount,
    });

    /**
     * Deploy Uniswap V3 Pool if not deployed
     */
    if (
        (
            await uniV3Factory.getPool(tokenA, tokenB, feeAmount)
        ).toLocaleLowerCase() ===
        hre.ethers.constants.AddressZero.toLocaleLowerCase()
    ) {
        await deployUniV3pool__task(
            {
                factory: uniV3Factory.address,
                positionManager: poolInitializer.address,
                feeTier: feeAmount,
                token0,
                token1,
                ratio0,
                ratio1,
                tag,
            },
            hre,
        );

        await VM.load([
            {
                name: deploymentName,
                address: computedPoolAddress,
                meta: {
                    token0,
                    token1,
                    ratio0,
                    ratio1,
                    fee: feeAmount,
                },
            },
        ]).save();
    } else {
        console.log(
            `[+] Uniswap V3 Pool already deployed at: ${computedPoolAddress}`,
        );
    }

    return {
        computedPoolAddress,
        token0,
        token1,
        ratio0,
        ratio1,
    };
};

async function loadContract(hre: HardhatRuntimeEnvironment, tag: string) {
    const uniV3Factory = await hre.ethers.getContractAt(
        'IUniswapV3Factory',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.V3_FACTORY,
    );
    const poolInitializer = await hre.ethers.getContractAt(
        'IPoolInitializer',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.NONFUNGIBLE_POSITION_MANAGER,
    );

    return {
        uniV3Factory,
        poolInitializer,
    };
}
