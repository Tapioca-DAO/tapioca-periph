import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { TapiocaMulticall } from '@tapioca-sdk/typechain/tapioca-periphery';
import { Token } from '@uniswap/sdk-core';
import { FeeAmount, computePoolAddress } from '@uniswap/v3-sdk';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployUniV3pool__task, loadGlobalContract } from 'tapioca-sdk';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

/**
 * Deploys TAP/WETH Uniswap V3 Pool.
 */
export const deployUniV3TapWethPool = async (
    hre: HardhatRuntimeEnvironment,
    tag: string,
    ratioTap: number,
    ratioWeth: number,
): Promise<TapiocaMulticall.CallStruct[]> => {
    const calls: TapiocaMulticall.CallStruct[] = [];
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });

    /**
     * Load contracts
     */
    const { tapToken, weth, uniV3Factory, poolInitializer } =
        await loadContract(hre, tag);

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
        const [ratio0, ratio1] = [ratioTap, ratioWeth];
        await deployUniV3pool__task(
            {
                factory: uniV3Factory.address,
                token0: tapToken.address,
                token1: weth.address,
                feeTier: FeeAmount.MEDIUM,
                positionManager: poolInitializer.address,
                ratio0,
                ratio1,
                tag,
            },
            hre,
        );

        VM.load([
            {
                name: DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL,
                address: computedPoolAddress,
                meta: {
                    tap: tapToken.address,
                    weth: weth.address,
                    fee: FeeAmount.MEDIUM,
                },
            },
        ]);
        await VM.save();
    }

    return calls;
};

async function loadContract(hre: HardhatRuntimeEnvironment, tag: string) {
    const weth = await hre.ethers.getContractAt(
        'ERC20',
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.WETH,
    );
    const tapToken = await hre.ethers.getContractAt(
        'ERC20',
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
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.V3_FACTORY,
    );

    return {
        tapToken,
        weth,
        uniV3Factory,
        poolInitializer,
    };
}
