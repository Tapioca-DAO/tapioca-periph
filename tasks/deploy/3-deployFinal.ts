import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract, loadLocalContract } from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from './DEPLOY_CONFIG';
import { Cluster, TapiocaMulticall } from '@typechain/index';
import { EChainID, TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import * as TAPIOCA_BAR_CONFIG from '@tapioca-bar/config';
import * as TAPIOCA_Z_CONFIG from '@tapiocaz/config';
import { deployUniPoolAndAddLiquidity } from 'tasks/deployBuilds/postLbp/deployUniPoolAndAddLiquidity';
import { FeeAmount } from '@uniswap/v3-sdk';
import { buildUsdoUsdcOracle } from 'tasks/deployBuilds/oracle/buildUsdoUsdcOracle';

/**
 * @notice Called after tapioca-bar postLbp2
 *
 * Deploys: Arb + Eth
 * - Arbitrum + Ethereum USDO/USDC pool
 * - USDO/USDC Oracle
 *
 * Post Deploy Setup: Arb + Eth
 * - Cluster Toe role setting (Magnetar)
 * - Cluster whitelist
 *      - Periph: (Magnetar, Pearlmit, Yieldbox)
 *      - Bar: (BB_MT_ETH_MARKET, BB_T_RETH_MARKET, BB_T_WST_ETH_MARKET, SGL_S_GLP_MARKET, MARKET_HELPER, USDO)
 *      - Bar: (SGL_S_DAI_MARKET)
 *      - Z: (tsGLP, mtETH, tRETH, tWSTETH, T_SGL_SDAI_MARKET, tsDAI)
 *      - Z Underlying: (WETH, rETH, wstETH, sGLP, sDAI)
 *
 */
export const deployFinal__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        ratioUsdo: number;
        ratioUsdc: number;
        amountUsdo: string;
        amountUsdc: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre },
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        deployTask,
        postDeployTask,
    );
};

async function postDeployTask(
    params: TTapiocaDeployerVmPass<{
        ratioUsdo: number;
        ratioUsdc: number;
        amountUsdo: string;
        amountUsdc: string;
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
        isSideChain,
    } = params;
    const { tag } = taskArgs;

    console.log('[+] final task post deploy');
    const calls: TapiocaMulticall.CallStruct[] = [];
    await clusterWhitelist({ hre, tag, calls, isHostChain, isSideChain });

    if (isTestnet) {
        console.log(
            '[+] [TESTNET] Setting USDO/USDC Oracle stale period to max ',
        );
        const usdoUsdcOracle = loadLocalContract(
            hre,
            hre.SDK.eChainId,
            DEPLOYMENT_NAMES.USDO_USDC_UNI_V3_ORACLE,
            tag,
        );
        const chainLinkUtils = await hre.ethers.getContractAt(
            'ChainlinkUtils',
            '',
        );
        calls.push({
            target: usdoUsdcOracle.address,
            callData: chainLinkUtils.interface.encodeFunctionData(
                'changeDefaultStalePeriod',
                [4294967295],
            ),
            allowFailure: false,
        });
    }

    await VM.executeMulticall(calls);
}

async function deployTask(
    params: TTapiocaDeployerVmPass<{
        ratioUsdo: number;
        ratioUsdc: number;
        amountUsdo: string;
        amountUsdc: string;
    }>,
) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, chainInfo, isTestnet } =
        params;
    const { tag } = taskArgs;

    console.log('[+] final deploy');

    await deployUsdoUniPoolAndAddLiquidity(params);

    // Add USDO oracle deployment
    const { usdo } = await deployPostLbpStack__loadContracts__arbitrum(
        hre,
        tag,
    );
    const usdoUsdcLpAddy = loadLocalContract(
        hre,
        hre.SDK.eChainId,
        DEPLOYMENT_NAMES.USDO_USDC_UNI_V3_POOL,
        tag,
    ).address;

    VM.add(
        await buildUsdoUsdcOracle({
            hre,
            isTestnet,
            owner: tapiocaMulticallAddr,
            usdoAddy: usdo,
            usdoUsdcLpAddy,
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
            tokenA: usdo,
            tokenB: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.USDC,
            ratioTokenA: taskArgs.ratioUsdo,
            ratioTokenB: taskArgs.ratioUsdc,
            amountTokenA: taskArgs.amountUsdo,
            amountTokenB: taskArgs.amountUsdc,
            feeAmount: FeeAmount.LOWEST,
            options: {
                mintMock: isTestnet,
                arrakisDepositLiquidity: true,
            },
        },
    });
}

async function clusterWhitelist(params: {
    hre: HardhatRuntimeEnvironment;
    tag: string;
    calls: TapiocaMulticall.CallStruct[];
    isHostChain: boolean;
    isSideChain: boolean;
}) {
    const { hre, tag, calls, isHostChain, isSideChain } = params;

    const { cluster, magnetar, pearlmit, yieldbox } =
        await deployPostLbpStack__loadContracts__generic(hre, tag);

    /**
     * Non chain specific
     */
    await addMagnetarToeRole({
        hre,
        cluster,
        magnetarAddr: magnetar.address,
        calls,
    });

    await addAddressWhitelist({
        name: 'Magnetar',
        address: magnetar.address,
        calls,
        cluster,
    });

    await addAddressWhitelist({
        name: 'Pearlmit',
        address: pearlmit,
        calls,
        cluster,
    });

    await addAddressWhitelist({
        name: 'YieldBox',
        address: yieldbox,
        calls,
        cluster,
    });

    /**
     * Chain specific
     */
    const addProjectContract = async (
        project: TAPIOCA_PROJECTS_NAME,
        name: string,
    ) => {
        await _addProjectContract({
            hre,
            project,
            name,
            tag,
            calls,
            cluster,
        });
    };
    const addBarContract = async (name: string) => {
        await addProjectContract(TAPIOCA_PROJECTS_NAME.TapiocaBar, name);
    };
    const addZContract = async (name: string) => {
        await addProjectContract(TAPIOCA_PROJECTS_NAME.TapiocaZ, name);
    };

    if (isHostChain) {
        // Bar
        await addBarContract(
            TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.BB_MT_ETH_MARKET,
        );
        await addBarContract(
            TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.BB_T_RETH_MARKET,
        );
        await addBarContract(
            TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.BB_T_WST_ETH_MARKET,
        );
        await addBarContract(
            TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.SGL_S_GLP_MARKET,
        );
        await addBarContract(TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.MARKET_HELPER);
        await addBarContract(TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.USDO);

        // Z
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tsGLP);
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.mtETH);
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tRETH);
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tWSTETH);
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.T_SGL_SDAI_MARKET);
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.T_SGL_GLP_MARKET);
        // Z Underlying
        await addAddressWhitelist({
            name: 'WETH',
            address:
                TAPIOCA_Z_CONFIG.DEPLOY_CONFIG.POST_LBP[hre.SDK.eChainId]!.WETH,
            calls,
            cluster,
        });
        await addAddressWhitelist({
            name: 'rETH',
            address:
                TAPIOCA_Z_CONFIG.DEPLOY_CONFIG.POST_LBP[hre.SDK.eChainId]!.reth,
            calls,
            cluster,
        });
        await addAddressWhitelist({
            name: 'wstETH',
            address:
                TAPIOCA_Z_CONFIG.DEPLOY_CONFIG.POST_LBP[hre.SDK.eChainId]!
                    .wstETH,
            calls,
            cluster,
        });
        await addAddressWhitelist({
            name: 'sGLP',
            address:
                TAPIOCA_Z_CONFIG.DEPLOY_CONFIG.POST_LBP[hre.SDK.eChainId]!.sGLP,
            calls,
            cluster,
        });
    }

    if (isSideChain) {
        // Bar
        await addBarContract(
            TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.SGL_S_DAI_MARKET,
        );
        // Z
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tsDAI);
        await addAddressWhitelist({
            name: 'sDAI',
            address:
                TAPIOCA_Z_CONFIG.DEPLOY_CONFIG.POST_LBP[hre.SDK.eChainId]!.sDAI,
            calls,
            cluster,
        });
    }
}

async function addMagnetarToeRole(params: {
    hre: HardhatRuntimeEnvironment;
    cluster: Cluster;
    magnetarAddr: string;
    calls: TapiocaMulticall.CallStruct[];
}) {
    const { hre, cluster, magnetarAddr, calls } = params;
    // Role setting not working
    const TOE_ROLE = hre.ethers.utils.keccak256(
        hre.ethers.utils.solidityPack(['string'], ['TOE']),
    ); // Role to be able to use TOE.sendPacketFrom()

    if (!(await cluster.hasRole(magnetarAddr, TOE_ROLE))) {
        console.log(`[+] Adding Magnetar ${magnetarAddr} to TOE role`);
        calls.push({
            target: cluster.address,
            callData: cluster.interface.encodeFunctionData(
                'setRoleForContract',
                [magnetarAddr, TOE_ROLE, true],
            ),
            allowFailure: false,
        });
    }
}

async function addAddressWhitelist(params: {
    name: string;
    address: string;
    cluster: Cluster;
    calls: TapiocaMulticall.CallStruct[];
}) {
    const { name, address, cluster, calls } = params;
    if (await cluster.isWhitelisted(0, address)) return;
    console.log(`[+] Adding ${name} ${address} to cluster whitelist`);
    calls.push({
        target: cluster.address,
        callData: cluster.interface.encodeFunctionData('updateContract', [
            0,
            address,
            true,
        ]),
        allowFailure: false,
    });
}

async function _addProjectContract(params: {
    hre: HardhatRuntimeEnvironment;
    project: TAPIOCA_PROJECTS_NAME;
    name: string;
    tag: string;
    calls: TapiocaMulticall.CallStruct[];
    cluster: Cluster;
}) {
    const { hre, name, tag, calls, cluster, project } = params;
    await addAddressWhitelist({
        calls,
        cluster,
        name,
        address: loadGlobalContract(hre, project, hre.SDK.eChainId, name, tag)
            .address,
    });
}

async function deployPostLbpStack__loadContracts__generic(
    hre: HardhatRuntimeEnvironment,
    tag: string,
) {
    const cluster = await hre.ethers.getContractAt(
        'Cluster',
        loadLocalContract(hre, hre.SDK.eChainId, DEPLOYMENT_NAMES.CLUSTER, tag)
            .address,
    );
    const magnetar = await hre.ethers.getContractAt(
        'Magnetar',
        loadLocalContract(hre, hre.SDK.eChainId, DEPLOYMENT_NAMES.MAGNETAR, tag)
            .address,
    );
    const pearlmit = loadLocalContract(
        hre,
        hre.SDK.eChainId,
        DEPLOYMENT_NAMES.PEARLMIT,
        tag,
    ).address;
    const yieldbox = loadLocalContract(
        hre,
        hre.SDK.eChainId,
        DEPLOYMENT_NAMES.YIELDBOX,
        tag,
    ).address;

    return { cluster, magnetar, pearlmit, yieldbox };
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
