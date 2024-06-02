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
import { ethers } from 'ethers';

export const DEPLOY_LBP_CONFIG: TLbp = {
    LBP_DURATION: 432000, // In seconds, 2 days 172800 on prod. 5 days 432000 on testnet
    START_BALANCES: [
        ethers.BigNumber.from(170_000).mul(1e6), // 6 decimals
        fp(5_000_000), // 18 decimals
    ], // 170k USDC, 5M LTAP
    START_WEIGHTS: [fp(0.01), fp(0.99)], // 1% USDC, 99% LTAP
    END_WEIGHTS: [fp(0.8), fp(0.2)], // 80% USDC, 20% LTAP
    SWAP_FEE_PERCENTAGE: fp(0.01), // 1%
    PAUSE_WINDOW_DURATION: 0,
    BUFFER_PERIOD_DURATION: 0,
};

/**
 * @notice Called after `deployPreLbpStack__task` & tap-token `deployPreLbpStack__task`
 *
 * Deploys:
 * - LBP Authorizer
 * - LBP Vault
 * - LBP LiquidityBootstrappingPool
 *
 * Post Deploy Setup:
 * - Set joining pool on vault
 * - Set swap enabled on LBP
 * - Set update weights gradually
 */
export const deployLbp__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        ltapAmount: string;
        usdcAmount: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre, staticSimulation: false },
        tapiocaDeployTask,
        postDeploySetupLbp,
    );
};

async function tapiocaDeployTask(
    params: TTapiocaDeployerVmPass<{
        ltapAmount: string;
        usdcAmount: string;
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
    } = params;
    const { tag, ltapAmount, usdcAmount } = taskArgs;
    const owner = tapiocaMulticallAddr;

    DEPLOY_LBP_CONFIG.START_BALANCES = [
        ethers.BigNumber.from(usdcAmount).mul(1e6), // 6 decimals
        fp(ltapAmount), // 18 decimals
    ];

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

    if (isHostChain) {
        console.log('[+] Deploying LBP with USDC and LTAP with values:');
        console.log(`    - USDC: ${Number(usdcAmount).toLocaleString()}`);
        console.log(`    - LTAP: ${Number(ltapAmount).toLocaleString()}`);

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
