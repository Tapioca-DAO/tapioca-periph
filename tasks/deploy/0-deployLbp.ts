import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract } from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildAuthorizer } from 'tasks/deployBuilds/lbp/buildAuthorizer';
import { buildLiquidityBootstrappingPool } from 'tasks/deployBuilds/lbp/buildLiquidityBootstrappingPool';
import { buildVault } from 'tasks/deployBuilds/lbp/buildVault';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG, TLbp } from './DEPLOY_CONFIG';
import { postDeploySetupLbp } from './postDeploy/0-postDeploySetupLbp';
import { fp } from 'tasks/deployBuilds/lbp/LBPNumbersUtils';

export const DEPLOY_LBP_CONFIG: TLbp = {
    LBP_DURATION: 172800, // In seconds, 2 days
    START_BALANCES: [fp(170_000), fp(5_000_000)], // 170k USDC, 5M LTAP
    START_WEIGHTS: [fp(0.01), fp(0.99)], // 01% USDC, 99% LTAP
    END_WEIGHTS: [fp(0.8), fp(0.2)], // 80% USDC, 20% LTAP
    SWAP_FEE_PERCENTAGE: fp(0.01), // 1%
    PAUSE_WINDOW_DURATION: 0,
    BUFFER_PERIOD_DURATION: 0,
};

/**
 * @notice Deploy TAP-TOKEN PRE-LBP stack
 */
export const deployLbp__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre, staticSimulation: false },
        tapiocaDeployTask,
        postDeploySetupLbp,
    );
};

async function tapiocaDeployTask(params: TTapiocaDeployerVmPass<object>) {
    const { hre, VM, tapiocaMulticallAddr, chainInfo, taskArgs, isTestnet } =
        params;
    const { tag } = taskArgs;
    const owner = tapiocaMulticallAddr;

    const { lTap } = deployLbp__getDeployments({ hre, tag });
    const [tokenA_Data, tokenB_Data] = [
        {
            token: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.USDC!,
            startWeight: DEPLOY_LBP_CONFIG.START_WEIGHTS[0],
        },
        {
            token: lTap.address,
            startWeight: DEPLOY_LBP_CONFIG.START_WEIGHTS[1],
        },
    ].sort((a, b) => deployLbp__compareAddresses(a.token, b.token));
    const tokens = [tokenA_Data.token, tokenB_Data.token];
    const startWeights = [tokenA_Data.startWeight, tokenB_Data.startWeight];

    if (
        chainInfo.name === 'arbitrum' ||
        chainInfo.name === 'arbitrum_sepolia'
    ) {
        VM.add(
            await buildAuthorizer(hre, DEPLOYMENT_NAMES.LBP_AUTHORIZER, {
                admin: owner,
            }),
        )
            .add(
                await buildVault(hre, DEPLOYMENT_NAMES.LBP_VAULT, {
                    authorizer: '',
                    bufferPeriodDuration:
                        DEPLOY_LBP_CONFIG.BUFFER_PERIOD_DURATION,
                    pauseWindowDuration:
                        DEPLOY_LBP_CONFIG.PAUSE_WINDOW_DURATION,
                    usdc: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.USDC!,
                }),
            )
            .add(
                await buildLiquidityBootstrappingPool(
                    hre,
                    DEPLOYMENT_NAMES.TAP_USDC_LBP,
                    {
                        vault: '',
                        name: 'Tapioca USDC/TAP LBP',
                        symbol: 'USDC/TAP LBP',
                        tokens,
                        normalizedWeights: startWeights,
                        swapFeePercentage:
                            DEPLOY_LBP_CONFIG.SWAP_FEE_PERCENTAGE,
                        pauseWindowDuration:
                            DEPLOY_LBP_CONFIG.PAUSE_WINDOW_DURATION,
                        bufferPeriodDuration:
                            DEPLOY_LBP_CONFIG.BUFFER_PERIOD_DURATION,
                        owner,
                        swapEnabledOnStart: false,
                    },
                ),
            );
    } else {
        throw new Error(
            `[-] Supported chains: Arbitrum, Arbitrum Sepolia. Current chain: ${chainInfo.name}`,
        );
    }
}

export function deployLbp__compareAddresses(
    tokenA: string,
    tokenB: string,
): number {
    return tokenA.toLowerCase() > tokenB.toLowerCase() ? 1 : -1;
}

export function deployLbp__getDeployments(params: {
    hre: HardhatRuntimeEnvironment;
    tag: string;
}) {
    const { hre, tag } = params;
    const lTap = loadGlobalContract(
        hre,
        TAPIOCA_PROJECTS_NAME.TapToken,
        hre.SDK.eChainId,
        TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.LTAP,
        tag,
    );
    return { lTap };
}
