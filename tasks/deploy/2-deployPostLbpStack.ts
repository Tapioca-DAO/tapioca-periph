import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract, loadLocalContract } from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildETHCLOracle } from 'tasks/deployBuilds/oracle/buildETHCLOracle';
import { buildETHUniOracle } from 'tasks/deployBuilds/oracle/buildETHUniOracle';
import { buildEthGlpPOracle } from 'tasks/deployBuilds/oracle/buildEthGlpOracle';
import { buildGLPOracle } from 'tasks/deployBuilds/oracle/buildGLPOracle';
import { buildGMXOracle } from 'tasks/deployBuilds/oracle/buildGMXOracle';
import { buildRethUsdOracle } from 'tasks/deployBuilds/oracle/buildRethUsdOracle';
import { buildSDaiOracle } from 'tasks/deployBuilds/oracle/buildSDaiOracle';
import {
    buildADBTapOptionOracle,
    buildTOBTapOptionOracle,
} from 'tasks/deployBuilds/oracle/buildTapOptionOracle';
import { buildTapOracle } from 'tasks/deployBuilds/oracle/buildTapOracle';
import { buildUSDCOracle } from 'tasks/deployBuilds/oracle/buildUSDCOracle';
import { buildWstethUsdOracle } from 'tasks/deployBuilds/oracle/buildWstethUsdOracle';
import { deployUniPoolAndAddLiquidity } from 'tasks/deployBuilds/postLbp/deployUniPoolAndAddLiquidity';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from './DEPLOY_CONFIG';
import { buildDualETHOracle } from 'tasks/deployBuilds/oracle/buildDualETHOracle';
import { createEmptyStratYbAsset__task } from './misc/createEmptyStratYbAsset';

/**
 * @notice Called only after tap-token repo `postLbp1` task
 */
export const deployPostLbpStack__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & { ratioTap: number; ratioWeth: number },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        {
            hre,
        },
        tapiocaDeployTask,
        postDeployTask,
    );
};

async function postDeployTask(
    params: TTapiocaDeployerVmPass<{ ratioTap: number; ratioWeth: number }>,
) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, chainInfo, isTestnet } =
        params;

    const { tapToken } = await loadContracts(hre, taskArgs.tag);

    // Used in Bar
    await createEmptyStratYbAsset__task(
        {
            ...taskArgs,
            token: tapToken.address,
            deploymentName: DEPLOYMENT_NAMES.TAP_TOKEN_YB_EMPTY_STRAT,
        },
        hre,
    );

    await createEmptyStratYbAsset__task(
        {
            ...taskArgs,
            token: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.WETH!,
            deploymentName: DEPLOYMENT_NAMES.WETH_YB_EMPTY_STRAT,
        },
        hre,
    );
}

async function tapiocaDeployTask(
    params: TTapiocaDeployerVmPass<{ ratioTap: number; ratioWeth: number }>,
) {
    const { hre, VM, tapiocaMulticallAddr, chainInfo, taskArgs, isTestnet } =
        params;
    const { tag } = taskArgs;
    const owner = tapiocaMulticallAddr;

    if (
        chainInfo.name === 'arbitrum' ||
        chainInfo.name === 'arbitrum_sepolia'
    ) {
        await deployUniPoolAndAddLiquidity(params);
        const { tapToken, tapWethLp } = await loadContracts(hre, tag);

        VM.add(await buildETHCLOracle(hre, owner, isTestnet))
            .add(await buildETHUniOracle(hre, owner, isTestnet))
            .add(await buildDualETHOracle(hre, owner))
            .add(await buildGLPOracle(hre, owner))
            .add(await buildEthGlpPOracle(hre, owner))
            .add(await buildGMXOracle(hre, owner, isTestnet))
            .add(
                await buildTapOracle(
                    hre,
                    tapToken.address,
                    tapWethLp.address,
                    owner,
                ),
            )
            .add(
                await buildADBTapOptionOracle(
                    hre,
                    tapToken.address,
                    tapWethLp.address,
                    owner,
                ),
            )
            .add(
                await buildTOBTapOptionOracle(
                    hre,
                    tapToken.address,
                    tapWethLp.address,
                    owner,
                ),
            )
            .add(await buildUSDCOracle(hre, owner, isTestnet))
            .add(await buildRethUsdOracle(hre, owner, isTestnet))
            .add(await buildWstethUsdOracle(hre, owner, isTestnet));
    } else if (chainInfo.name === 'ethereum' || chainInfo.name === 'sepolia') {
        VM.add(await buildSDaiOracle(hre, owner));
    }
}

async function loadContracts(hre: HardhatRuntimeEnvironment, tag: string) {
    // TapToken
    const tapToken = loadGlobalContract(
        hre,
        TAPIOCA_PROJECTS_NAME.TapToken,
        hre.SDK.eChainId,
        TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN,
        tag,
    );

    const tapWethLp = loadLocalContract(
        hre,
        hre.SDK.eChainId,
        DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL,
        tag,
    );

    return { tapToken, tapWethLp };
}
