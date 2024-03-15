import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract } from 'tapioca-sdk';
import {
    DeployerVM,
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildDaiOracle } from 'tasks/deployBuilds/oracle/buildDaiOracle';
import { buildETHOracle } from 'tasks/deployBuilds/oracle/buildETHOracle';
import { buildEthGlpPOracle } from 'tasks/deployBuilds/oracle/buildEthGlpOracle';
import { buildGLPOracle } from 'tasks/deployBuilds/oracle/buildGLPOracle';
import { buildGMXOracle } from 'tasks/deployBuilds/oracle/buildGMXOracle';
import { buildTapOptionOracle } from 'tasks/deployBuilds/oracle/buildTapOptionOracle';
import { buildTapOracle } from 'tasks/deployBuilds/oracle/buildTapOracle';
import { DEPLOY_CONFIG } from './DEPLOY_CONFIG';
import { deployUniV3pool__task } from './misc/deployUniV3Pool';

export const deployPostLbpStack__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
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

async function tapiocaDeployTask(params: TTapiocaDeployerVmPass<object>) {
    const { hre, VM, tapiocaMulticallAddr, chainInfo, taskArgs, isTestnet } =
        params;
    const owner = tapiocaMulticallAddr;

    if (isTestnet) {
        await deployUniV3MockPool({
            hre,
            taskArgs,
            tag: taskArgs.tag,
        });
    }

    const { tapToken, tapWethLp } = await loadContracts(
        hre,
        taskArgs.tag,
        isTestnet,
    );

    if (
        chainInfo.name === 'arbitrum' ||
        chainInfo.name === 'arbitrum_sepolia'
    ) {
        VM.add(await buildETHOracle(hre, owner))
            .add(await buildGLPOracle(hre, owner))
            .add(await buildEthGlpPOracle(hre, owner))
            .add(await buildGMXOracle(hre, owner))
            .add(
                await buildTapOptionOracle(
                    hre,
                    tapToken.address,
                    tapWethLp.address,
                    owner,
                ),
            )
            .add(
                await buildTapOracle(
                    hre,
                    tapToken.address,
                    tapWethLp.address,
                    owner,
                ),
            );
    } else if (chainInfo.name === 'ethereum' || chainInfo.name === 'sepolia') {
        VM.add(await buildDaiOracle(hre, owner));
    }
}

async function loadContracts(
    hre: HardhatRuntimeEnvironment,
    tag: string,
    isTestnet: boolean,
) {
    // TapToken
    const tapToken = loadGlobalContract(
        hre,
        TAPIOCA_PROJECTS_NAME.TapToken,
        hre.SDK.eChainId,
        TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN,
        tag,
    );

    let tapWethLp;
    if (isTestnet) {
        // TODO - remove this once we deploy the pool on TapToken
        tapWethLp = loadGlobalContract(
            hre,
            TAPIOCA_PROJECTS_NAME.TapToken,
            hre.SDK.eChainId,
            `${TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL}_MOCK`,
            tag,
        );
    } else {
        tapWethLp = loadGlobalContract(
            hre,
            TAPIOCA_PROJECTS_NAME.TapToken,
            hre.SDK.eChainId,
            TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL,
            tag,
        );
    }

    return { tapToken, tapWethLp };
}

// TODO - remove this once we deploy the pool on TapToken
async function deployUniV3MockPool(params: {
    hre: HardhatRuntimeEnvironment;
    taskArgs: TTapiocaDeployTaskArgs;
    tag: string;
}) {
    const { hre, taskArgs, tag } = params;
    const tapToken = loadGlobalContract(
        hre,
        TAPIOCA_PROJECTS_NAME.TapToken,
        hre.SDK.eChainId,
        TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN,
        tag,
    );

    const deploymentName = `${TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL}_MOCK`;
    try {
        loadGlobalContract(
            hre,
            TAPIOCA_PROJECTS_NAME.TapToken,
            hre.SDK.eChainId,
            deploymentName,
            tag,
        );
    } catch (e) {
        const poolAddress = await deployUniV3pool__task(
            {
                ...taskArgs,
                feeTier: 3000,
                token0: tapToken.address,
                token1: DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.WETH,
                ratio0: 33,
                ratio1: 10,
            },
            hre,
        );
        hre.SDK.db.saveGlobally(
            {
                [hre.SDK.eChainId]: {
                    name: hre.network.name,
                    lastBlockHeight: await hre.ethers.provider.getBlockNumber(),
                    contracts: [
                        {
                            address: poolAddress,
                            name: `${TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL}_MOCK`,
                            meta: {},
                        },
                    ],
                },
            },
            TAPIOCA_PROJECTS_NAME.TapToken,
            tag,
        );
    }
}
