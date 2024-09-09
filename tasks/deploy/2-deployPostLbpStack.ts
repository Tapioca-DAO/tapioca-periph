import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract, loadLocalContract } from 'tapioca-sdk';
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
import { buildStgCLOracle } from 'tasks/deployBuilds/oracle/buildStgCLOracle';
import {
    buildADBTapOptionOracle,
    buildTOBTapOptionOracle,
} from 'tasks/deployBuilds/oracle/buildTapOptionOracle';
import { buildTapOracle } from 'tasks/deployBuilds/oracle/buildTapOracle';
import { buildUSDCOracle } from 'tasks/deployBuilds/oracle/buildUSDCOracle';
import { buildUsdoMarketOracle } from 'tasks/deployBuilds/oracle/buildUsdoMarketOracle';
import { buildWstethUsdOracle } from 'tasks/deployBuilds/oracle/buildWstethUsdOracle';
import { DEPLOYMENT_NAMES } from './DEPLOY_CONFIG';
import { deployPostLbpStack__postDeploy } from './postDeploy/2-postDeploySetup';
import { buildArbCLOracle } from 'tasks/deployBuilds/oracle/buildArbClOracle';

/**
 * @notice Called only after tap-token repo `postLbp1` task
 * Deploy: Arb,Eth
 *      - TAP/WETH Uniswap V3 pool
 *      - Oracles:
 *          - Arbitrum:
 *              - ETH CL, ETH Uni, Dual ETH, GLP, ETH/GLP, GMX, TAP, TapOption, USDC, rETH, wstETH
 *          - Ethereum:
 *              - sDAI
 * Post deploy: Arb,Eth
 * !!! Requires TAP and WETH tokens to be in the TapiocaMulticall contract (UniV3 pool creation)
 * !!! Requires TAP and WETH tokens to be in the TapiocaMulticall contract (YB deposit)
 *     - Create empty YB strat for TAP and WETH and register them in YB
 *     - Deposit YB assets in YB
 *     - Set Seer staleness on testnet
 *
 */
export const deployPostLbpStack__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        ratioTap: number;
        ratioWeth: number;
        amountTap: string;
        amountWeth: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        {
            hre,
            staticSimulation: false, // Can't runs static simulation because constructor will try to call inexistent contract/function
            overrideOptions: {
                gasLimit: 10_000_000,
            },
        },
        tapiocaDeployTask,
        deployPostLbpStack__postDeploy,
    );
};

async function tapiocaDeployTask(
    params: TTapiocaDeployerVmPass<{
        ratioTap: number;
        ratioWeth: number;
        amountTap: string;
        amountWeth: string;
    }>,
) {
    const {
        hre,
        VM,
        tapiocaMulticallAddr,
        chainInfo,
        taskArgs,
        isTestnet,
        isHostChain,
        isSideChain,
    } = params;
    const { tag } = taskArgs;
    const owner = tapiocaMulticallAddr;

    // DO NOT USE FOR PROD FINAL
    if (isHostChain) {
        const { tapToken } = deployPostLbpStack__task__loadContracts__generic(
            hre,
            tag,
        );
        // if (tag != 'lbp-prod-deployment') {
        //     await deployUniPoolAndAddLiquidity({
        //         ...params,
        //         taskArgs: {
        //             ...taskArgs,
        //             deploymentName: DEPLOYMENT_NAMES.TAP_WETH_UNI_V3_POOL,
        //             arrakisDeploymentName:
        //                 DEPLOYMENT_NAMES.ARRAKIS_TAP_WETH_VAULT,
        //             tokenToInitArrakisShares: tapToken.address,
        //             tokenA: tapToken.address,
        //             tokenB: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.WETH!,
        //             ratioTokenA: taskArgs.ratioTap,
        //             ratioTokenB: taskArgs.ratioWeth,
        //             amountTokenA: hre.ethers.utils.parseEther(
        //                 taskArgs.amountTap,
        //             ),
        //             amountTokenB: hre.ethers.utils.parseEther(
        //                 taskArgs.amountWeth,
        //             ),
        //             feeAmount: FeeAmount.HIGH,
        //             options: {
        //                 mintMock: !!isTestnet,
        //                 arrakisDepositLiquidity: false,
        //             },
        //         },
        //     });
        // }
    }

    if (isHostChain) {
        // TapWethLp is used in the oracles, so it must be deployed first
        // Deployment happens above in `deployUniPoolAndAddLiquidity`
        const { tapToken, tapWethLp } =
            deployPostLbpStack__task__loadContracts__arb(hre, tag);

        VM.add(await buildETHCLOracle(hre, owner, isTestnet))
            .add(await buildETHUniOracle(hre, owner, isTestnet))
            .add(await buildDualETHOracle(hre, owner))
            .add(await buildGLPOracle(hre, owner))
            .add(await buildEthGlpPOracle(hre, owner))
            .add(await buildGMXOracle(hre, owner, isTestnet))
            .add(await buildArbCLOracle(hre, owner, isTestnet))
            .add(await buildStgCLOracle(hre, owner, isTestnet))
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
                    deploymentName: DEPLOYMENT_NAMES.MARKET_TETH_ORACLE,
                    args: ['', owner],
                    dependsOn: [
                        {
                            argPosition: 0,
                            deploymentName:
                                DEPLOYMENT_NAMES.ETH_SEER_DUAL_ORACLE,
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
    } else if (isSideChain) {
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

export function deployPostLbpStack__task__loadContracts__generic(
    hre: HardhatRuntimeEnvironment,
    tag: string,
) {
    const tapToken = loadGlobalContract(
        hre,
        TAPIOCA_PROJECTS_NAME.TapToken,
        hre.SDK.eChainId,
        TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN,
        tag,
    );

    return { tapToken };
}

export function deployPostLbpStack__task__loadContracts__arb(
    hre: HardhatRuntimeEnvironment,
    tag: string,
) {
    const { tapToken } = deployPostLbpStack__task__loadContracts__generic(
        hre,
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
