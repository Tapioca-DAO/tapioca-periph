import * as TAPIOCA_BAR_CONFIG from '@tapioca-bar/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { FeeAmount } from '@uniswap/v3-sdk';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract, loadLocalContract } from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildUsdoUsdcOracle } from 'tasks/deployBuilds/oracle/buildUsdoUsdcOracle';
import { deployUniPoolAndAddLiquidity } from 'tasks/deployBuilds/postLbp/deployUniPoolAndAddLiquidity';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from './DEPLOY_CONFIG';

/**
 * @notice Called after tapioca-bar postLbp2
 *
 * Deploys: Arb + Eth
 * - Arbitrum + Ethereum USDO/USDC pool
 * - USDO/USDC Oracle
 */
export const deployFinal1__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        usdoPoolAddr: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        {
            hre,
            overrideOptions: {
                gasLimit: 8000000,
            },
        },
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        deployTask,
    );
};

async function deployTask(
    params: TTapiocaDeployerVmPass<{
        usdoPoolAddr: string;
    }>,
) {
    const {
        hre,
        VM,
        tapiocaMulticallAddr,
        taskArgs,
        chainInfo,
        isTestnet,
        isHostChain,
    } = params;
    const { tag } = taskArgs;

    console.log('[+] final deploy');

    if (isHostChain) {
        // await deployUsdoUniPoolAndAddLiquidity(params);
    }

    // Add USDO oracle deployment
    const { usdo } = await deployPostLbpStack__loadContracts__arbitrum(
        hre,
        tag,
    );

    VM.add(
        await buildUsdoUsdcOracle({
            hre,
            isTestnet,
            owner: tapiocaMulticallAddr,
            usdoAddy: usdo,
            usdoUsdcLpAddy: taskArgs.usdoPoolAddr,
        }),
    );
}

async function deployUsdoUniPoolAndAddLiquidity(
    params: TTapiocaDeployerVmPass<{
        ratioUsdo: number;
        ratioUsdc: number;
        amountUsdo: string;
        amountUsdc: string;
    }>,
) {
    const { hre, taskArgs, chainInfo, isTestnet, isHostChain, isSideChain } =
        params;
    const { tag } = taskArgs;
    const { usdo } = await deployPostLbpStack__loadContracts__arbitrum(
        hre,
        tag,
    );
    console.log('[+] Deploying Arbitrum USDO/USDC pool');
    await deployUniPoolAndAddLiquidity({
        ...params,
        taskArgs: {
            ...taskArgs,
            deploymentName: DEPLOYMENT_NAMES.USDO_USDC_UNI_V3_POOL,
            arrakisDeploymentName: DEPLOYMENT_NAMES.ARRAKIS_USDO_USDC_VAULT,
            tokenA: usdo,
            tokenB: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.USDC,
            tokenToInitArrakisShares: usdo,
            ratioTokenA: taskArgs.ratioUsdo,
            ratioTokenB: taskArgs.ratioUsdc,
            amountTokenA: hre.ethers.utils.parseEther(taskArgs.amountUsdo),
            amountTokenB: hre.ethers.utils.parseEther(taskArgs.amountUsdc),
            feeAmount: FeeAmount.LOWEST,
            options: {
                mintMock: !!isTestnet,
                arrakisDepositLiquidity: false,
            },
        },
    });
}

async function deployPostLbpStack__loadContracts__arbitrum(
    hre: HardhatRuntimeEnvironment,
    tag: string,
) {
    const usdo = loadGlobalContract(
        hre,
        TAPIOCA_PROJECTS_NAME.TapiocaBar,
        hre.SDK.eChainId,
        TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.USDO,
        tag,
    ).address;

    return { usdo };
}
