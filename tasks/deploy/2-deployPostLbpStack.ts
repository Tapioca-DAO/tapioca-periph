import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract, loadLocalContract } from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildDaiOracle } from 'tasks/deployBuilds/oracle/buildDaiOracle';
import { buildETHOracle } from 'tasks/deployBuilds/oracle/buildETHOracle';
import { buildEthGlpPOracle } from 'tasks/deployBuilds/oracle/buildEthGlpOracle';
import { buildGLPOracle } from 'tasks/deployBuilds/oracle/buildGLPOracle';
import { buildGMXOracle } from 'tasks/deployBuilds/oracle/buildGMXOracle';
import {
    buildADBTapOptionOracle,
    buildTOBTapOptionOracle,
} from 'tasks/deployBuilds/oracle/buildTapOptionOracle';
import { buildTapOracle } from 'tasks/deployBuilds/oracle/buildTapOracle';
import { buildUSDCOracle } from 'tasks/deployBuilds/oracle/buildUSDCOracle';
import { deployUniPoolAndAddLiquidity } from 'tasks/deployBuilds/postLbp/deployUniPoolAndAddLiquidity';
import { DEPLOYMENT_NAMES } from './DEPLOY_CONFIG';

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
    );
};

async function tapiocaDeployTask(
    params: TTapiocaDeployerVmPass<{ ratioTap: number; ratioWeth: number }>,
) {
    const { hre, VM, tapiocaMulticallAddr, chainInfo, taskArgs } = params;
    const { tag } = taskArgs;
    const owner = tapiocaMulticallAddr;

    if (
        chainInfo.name === 'arbitrum' ||
        chainInfo.name === 'arbitrum_sepolia'
    ) {
        await deployUniPoolAndAddLiquidity(params);
        const { tapToken, tapWethLp } = await loadContracts(hre, tag);

        VM.add(await buildETHOracle(hre, owner))
            .add(await buildGLPOracle(hre, owner))
            .add(await buildEthGlpPOracle(hre, owner))
            .add(await buildGMXOracle(hre, owner))
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
            .add(await buildUSDCOracle(hre, owner));
    } else if (chainInfo.name === 'ethereum' || chainInfo.name === 'sepolia') {
        VM.add(await buildDaiOracle(hre, owner));
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
