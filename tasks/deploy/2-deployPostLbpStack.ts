import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import {
    createEmptyStratYbAsset__task,
    loadGlobalContract,
    loadLocalContract,
} from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildDualETHOracle } from 'tasks/deployBuilds/oracle/buildDualETHOracle';
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
import { buildUsdoMarketOracle } from 'tasks/deployBuilds/oracle/buildUsdoMarketOracle';
import { buildWstethUsdOracle } from 'tasks/deployBuilds/oracle/buildWstethUsdOracle';
import { deployUniPoolAndAddLiquidity } from 'tasks/deployBuilds/postLbp/deployUniPoolAndAddLiquidity';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from './DEPLOY_CONFIG';

/**
 * @notice Called only after tap-token repo `postLbp1` task
 * Deploy:
 *      - TAP/WETH Uniswap V3 pool
 *      - Oracles:
 *          - Arbitrum:
 *              - ETH CL, ETH Uni, Dual ETH, GLP, ETH/GLP, GMX, TAP, TapOption, USDC, rETH, wstETH
 *          - Ethereum:
 *              - sDAI
 * Post deploy:
 *     - Create empty strat for TAP and WETH
 *
 *
 */
export const deployPostLbpStack__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & { ratioTap: number; ratioWeth: number },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre, bytecodeSizeLimit: 80_000 },
        tapiocaDeployTask,
        postDeployTask,
    );
};

async function postDeployTask(
    params: TTapiocaDeployerVmPass<{ ratioTap: number; ratioWeth: number }>,
) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, chainInfo, isTestnet } =
        params;

    const { tapToken } = loadContracts__generic(hre, taskArgs.tag);

    // Used in Bar Penrose register
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
        const { tapToken, tapWethLp } = loadContracts__arb(hre, tag);

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
            .add(await buildWstethUsdOracle(hre, owner, isTestnet))
            .add(
                await buildUsdoMarketOracle(hre, {
                    deploymentName: DEPLOYMENT_NAMES.MARKET_RETH_ORACLE,
                    args: ['', owner],
                    dependsOn: [
                        {
                            argPosition: 0,
                            deploymentName:
                                DEPLOYMENT_NAMES.RETH_USD_SEER_CL_MULTI_ORACLE,
                        },
                    ],
                }),
            )
            .add(
                await buildUsdoMarketOracle(hre, {
                    deploymentName: DEPLOYMENT_NAMES.MARKET_WSTETH_ORACLE,
                    args: ['', owner],
                    dependsOn: [
                        {
                            argPosition: 0,
                            deploymentName:
                                DEPLOYMENT_NAMES.WSTETH_USD_SEER_CL_MULTI_ORACLE,
                        },
                    ],
                }),
            )
            .add(
                await buildUsdoMarketOracle(hre, {
                    deploymentName: DEPLOYMENT_NAMES.MARKET_GLP_ORACLE,
                    args: ['', owner],
                    dependsOn: [
                        {
                            argPosition: 0,
                            deploymentName: DEPLOYMENT_NAMES.GLP_ORACLE,
                        },
                    ],
                }),
            );
    } else if (
        chainInfo.name === 'ethereum' ||
        chainInfo.name === 'sepolia' ||
        chainInfo.name === 'optimism_sepolia'
    ) {
        VM.add(await buildSDaiOracle(hre)).add(
            await buildUsdoMarketOracle(hre, {
                deploymentName: DEPLOYMENT_NAMES.MARKET_SDAI_ORACLE,
                args: ['', owner],
                dependsOn: [
                    {
                        argPosition: 0,
                        deploymentName: DEPLOYMENT_NAMES.S_DAI_ORACLE,
                    },
                ],
            }),
        );
    }
}

function loadContracts__generic(hre: HardhatRuntimeEnvironment, tag: string) {
    const tapToken = loadGlobalContract(
        hre,
        TAPIOCA_PROJECTS_NAME.TapToken,
        hre.SDK.eChainId,
        TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN,
        tag,
    );
    return { tapToken };
}

function loadContracts__arb(hre: HardhatRuntimeEnvironment, tag: string) {
    const { tapToken } = loadContracts__generic(hre, tag);

    const tapWethLp = loadLocalContract(
        hre,
        hre.SDK.eChainId,
        DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL,
        tag,
    );

    return { tapToken, tapWethLp };
}
