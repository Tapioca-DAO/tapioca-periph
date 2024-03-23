import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { Token } from '@uniswap/sdk-core';
import { FeeAmount, computePoolAddress } from '@uniswap/v3-sdk';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployUniV3pool__task, loadGlobalContract } from 'tapioca-sdk';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

/**
 * @notice Deploys TAP/WETH Uniswap V3 Pool.
 * @returns Address of the deployed pool
 */
export const deployUniV3TapWethPool = async (
    hre: HardhatRuntimeEnvironment,
    tag: string,
    ratioTap: number,
    ratioWeth: number,
) => {
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });

    /**
     * Load contracts
     */
    const { tapToken, weth, uniV3Factory, poolInitializer } =
        await loadContract(hre, tag);
    const [token0, ratio0, token1, ratio1] =
        tapToken.address < weth.address
            ? [tapToken.address, ratioTap, weth.address, ratioWeth]
            : [weth.address, ratioWeth, tapToken.address, ratioTap];

    const computedPoolAddress = computePoolAddress({
        factoryAddress: uniV3Factory.address,
        tokenA: new Token(hre.network.config.chainId!, tapToken.address, 18),
        tokenB: new Token(hre.network.config.chainId!, weth.address, 18),
        fee: FeeAmount.MEDIUM,
    });

    /**
     * Deploy Uniswap V3 Pool if not deployed
     */
    if (
        (
            await uniV3Factory.getPool(
                tapToken.address,
                weth.address,
                FeeAmount.MEDIUM,
            )
        ).toLocaleLowerCase() ===
        hre.ethers.constants.AddressZero.toLocaleLowerCase()
    ) {
        await deployUniV3pool__task(
            {
                factory: uniV3Factory.address,
                positionManager: poolInitializer.address,
                feeTier: FeeAmount.MEDIUM,
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
                name: DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL,
                address: computedPoolAddress,
                meta: {
                    token0,
                    token1,
                    ratio0,
                    ratio1,
                    fee: FeeAmount.MEDIUM,
                },
            },
        ]).save();
    }

    return {
        computedPoolAddress,
        token0,
        token1,
        ratio0,
        ratio1,
        fee: FeeAmount.MEDIUM,
    };
};

async function loadContract(hre: HardhatRuntimeEnvironment, tag: string) {
    const weth = await hre.ethers.getContractAt(
        'ForgeIERC20',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.WETH,
    );
    const tapToken = await hre.ethers.getContractAt(
        'ForgeIERC20',
        loadGlobalContract(
            hre,
            TAPIOCA_PROJECTS_NAME.TapToken,
            hre.SDK.eChainId,
            TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN,
            tag,
        ).address,
    );
    const uniV3Factory = await hre.ethers.getContractAt(
        'IUniswapV3Factory',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.V3_FACTORY,
    );
    const poolInitializer = await hre.ethers.getContractAt(
        'IPoolInitializer',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.NONFUNGIBLE_POSITION_MANAGER,
    );

    return {
        tapToken,
        weth,
        uniV3Factory,
        poolInitializer,
    };
}
