import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildDaiOracle } from 'tasks/deployBuilds/oracle/buildDaiOracle';
import { buildETHOracle } from 'tasks/deployBuilds/oracle/buildETHOracle';
import { buildEthGlpPOracle } from 'tasks/deployBuilds/oracle/buildEthGlpOracle';
import { buildGLPOracle } from 'tasks/deployBuilds/oracle/buildGLPOracle';
import { buildGMXOracle } from 'tasks/deployBuilds/oracle/buildGMXOracle';
import { buildTapOptionOracle } from 'tasks/deployBuilds/oracle/buildTapOptionOracle';
import { buildTapOracle } from 'tasks/deployBuilds/oracle/buildTapOracle';

export const deployPostLbpStack__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    return await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        hre,
        async ({ VM, tapiocaMulticallAddr, chainInfo, taskArgs }) => {
            const owner = tapiocaMulticallAddr;
            const { tapToken, tapWethLp } = await loadContracts(
                hre,
                taskArgs.tag,
            );
            if (
                chainInfo.name === 'arbitrum' ||
                chainInfo.name === 'arbitrum_sepolia'
            ) {
                VM.add(await buildETHOracle(hre, owner))
                    .add(await buildGLPOracle(hre, owner))
                    .add(await buildEthGlpPOracle(hre, tapiocaMulticallAddr))
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
            } else if (
                chainInfo.name === 'ethereum' ||
                chainInfo.name === 'sepolia'
            ) {
                VM.add(await buildDaiOracle(hre, owner));
            }
        },
    );
};

async function loadContracts(hre: HardhatRuntimeEnvironment, tag: string) {
    // TapToken
    const tapToken = hre.SDK.db.findGlobalDeployment(
        TAPIOCA_PROJECTS_NAME.TapToken,
        hre.SDK.eChainId,
        TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN,
        tag,
    );
    if (!tapToken) {
        throw `[-] ${
            TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN
        } from TAP_TOKEN contract repo not deployed on ${
            hre.SDK.utils.getChainBy('chainId', hre.SDK.eChainId)!.name
        } tag ${tag}`;
    }

    // TapWethLp
    const tapWethLp = hre.SDK.db.findGlobalDeployment(
        TAPIOCA_PROJECTS_NAME.TapToken,
        hre.SDK.eChainId,
        TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL,
        tag,
    );
    if (!tapWethLp) {
        throw `[-] ${
            TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL
        } from TAP_TOKEN repo not deployed on ${
            hre.SDK.utils.getChainBy('chainId', hre.SDK.eChainId)!.name
        }`;
    }

    return { tapToken, tapWethLp };
}
