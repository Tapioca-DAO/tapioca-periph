import * as TAP_TOKEN_CONFIG from '@tap-token/config';
import * as TAPIOCA_BAR_CONFIG from '@tapioca-bar/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import * as TAPIOCA_Z_CONFIG from '@tapiocaz/config';
import { Cluster, TapiocaMulticall } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract, loadLocalContract } from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from './DEPLOY_CONFIG';

/**
 * @notice Called after tap-token final
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
export const deployFinal2__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre },
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        async () => {},
        postDeployTask,
    );
};

async function postDeployTask(params: TTapiocaDeployerVmPass<object>) {
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
    await clusterWhitelist({
        hre,
        tag,
        calls,
        isHostChain,
        isSideChain,
        isTestnet,
        tapiocaMulticallAddr,
    });

    if (isTestnet && isHostChain) {
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

async function clusterWhitelist(params: {
    hre: HardhatRuntimeEnvironment;
    tag: string;
    calls: TapiocaMulticall.CallStruct[];
    isHostChain: boolean;
    isSideChain: boolean;
    isTestnet: boolean;
    tapiocaMulticallAddr: string;
}) {
    const {
        hre,
        tag,
        calls,
        isHostChain,
        isSideChain,
        isTestnet,
        tapiocaMulticallAddr,
    } = params;

    const { cluster, magnetar, pearlmit, yieldbox, pauser } =
        await deployPostLbpStack__loadContracts__generic(hre, tag);

    /**
     * Non chain specific
     */
    await addRoleForContract({
        hre,
        cluster,
        target: magnetar.address,
        role: 'TOE',
        calls,
    });
    await addRoleForContract({
        hre,
        cluster,
        target: pauser,
        role: 'PAUSER',
        calls,
    });
    await addRoleForContract({
        hre,
        cluster,
        target: magnetar.address,
        role: 'MAGNETAR',
        calls,
    });
    await addRoleForContract({
        hre,
        cluster,
        target: tapiocaMulticallAddr,
        role: 'NEW_EPOCH',
        calls,
    });
    await addRoleForContract({
        hre,
        cluster,
        target: '0x6918175a68E3A6aD653AdF8Dab6322De1B5a72c1', // Peter address
        role: 'NEW_EPOCH',
        calls,
    });

    await addAddressWhitelist({
        name: 'Peters address',
        address: '0x6918175a68E3A6aD653AdF8Dab6322De1B5a72c1',
        calls,
        cluster,
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

    // await addAddressWhitelist({
    //     name: 'SwapperMock',
    //     address: '0xEfDf194d1Fa592a0c0c7E9E5Af681cd6Cc30D421', // Swapper mock
    //     calls,
    //     cluster,
    // });

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
    const addTapContract = async (name: string) => {
        await addProjectContract(TAPIOCA_PROJECTS_NAME.TapToken, name);
    };

    await addBarContract(TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.MARKET_HELPER);
    await addBarContract(TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.USDO);

    if (isTestnet) {
        await _addLocalContract({
            hre,
            name: DEPLOYMENT_NAMES.ZERO_X_SWAPPER_MOCK,
            tag,
            calls,
            cluster,
        });
        // const zeroXSwapperMock = loadLocalContract(
        //     hre,
        //     hre.SDK.eChainId,
        //     DEPLOYMENT_NAMES.ZERO_X_SWAPPER_MOCK,
        //     tag,
        // ).address;

        // // const addSwapperMockWhitelist = async (name: string) => {
        // //     await addMockWhitelist({
        // //         hre,
        // //         tag,
        // //         address: zeroXSwapperMock,
        // //         calls,
        // //         name,
        // //     });
        // // };
        // // await addSwapperMockWhitelist(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tETH);
        // // await addSwapperMockWhitelist(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.mtETH);
        // // await addSwapperMockWhitelist(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tRETH);
        // // await addSwapperMockWhitelist(
        // //     TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tWSTETH,
        // // );
        // // await addSwapperMockWhitelist(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tZRO);
        // // await addSwapperMockWhitelist(
        // //     TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tStgUsdcV2,
        // // );
    }

    if (isHostChain) {
        await addAddressWhitelist({
            name: 'USDC',
            address: DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.USDC,
            calls,
            cluster,
        });

        // Tap
        await addTapContract(TAP_TOKEN_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN);
        await addTapContract(TAP_TOKEN_CONFIG.DEPLOYMENT_NAMES.OTAP);
        await addTapContract(TAP_TOKEN_CONFIG.DEPLOYMENT_NAMES.TWTAP);
        await addTapContract(
            TAP_TOKEN_CONFIG.DEPLOYMENT_NAMES.TAPIOCA_OPTION_BROKER,
        );
        await addTapContract(
            TAP_TOKEN_CONFIG.DEPLOYMENT_NAMES
                .TAPIOCA_OPTION_LIQUIDITY_PROVISION,
        );

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

        // await addBarContract(
        //     TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.SGL_S_GLP_MARKET,
        // );

        if (isTestnet) {
            await addBarContract(
                TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.BB_T_ZRO_MARKET,
            );
            await addBarContract(
                TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.SGL_STG_USDC_V2_MARKET,
            );
            await addBarContract(
                TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.SGL_USDC_MOCK_MARKET,
            );

            await addBarContract(
                TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.SIMPLE_LEVERAGE_EXECUTOR,
            );
        }
        if (!isTestnet) {
            await addBarContract(
                TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.SGL_GLP_LEVERAGE_EXECUTOR,
            );
        }

        // Z
        // await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tsGLP);
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.mtETH);
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tRETH);
        await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tWSTETH);

        // await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.T_SGL_SDAI_MARKET);
        // await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.T_SGL_GLP_MARKET);

        if (isTestnet) {
            await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tZRO);
            await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tStgUsdcV2);
            await addZContract(
                TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.T_SGL_STG_USDC_V2_MARKET,
            );
            // await addZContract(
            //     TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.T_SGL_USDC_MOCK_MARKET,
            // );
        }

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

        // await addAddressWhitelist({
        //     name: 'sGLP',
        //     address:
        //         TAPIOCA_Z_CONFIG.DEPLOY_CONFIG.POST_LBP[hre.SDK.eChainId]!.sGLP,
        //     calls,
        //     cluster,
        // });

        if (isTestnet) {
            await addAddressWhitelist({
                name: 'Zro',
                address:
                    TAPIOCA_Z_CONFIG.DEPLOY_CONFIG.POST_LBP[hre.SDK.eChainId]!
                        .zro,
                calls,
                cluster,
            });
            await addAddressWhitelist({
                name: 'stgUsdcV2',
                address: '0x94c6f996e3423C8e32cc61Fa5244AD110E02CD2D',
                calls,
                cluster,
            });
            await addAddressWhitelist({
                name: 'StgUsdcV2',
                address:
                    TAPIOCA_Z_CONFIG.DEPLOY_CONFIG.POST_LBP[hre.SDK.eChainId]!
                        .stgUsdcV2,
                calls,
                cluster,
            });
        }
    }

    if (isSideChain) {
        // Tap
        await addTapContract(TAP_TOKEN_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN);

        // Bar
        await addBarContract(
            TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.SGL_S_DAI_MARKET,
        );
        // Z
        // await addZContract(TAPIOCA_Z_CONFIG.DEPLOYMENT_NAMES.tsDAI);

        await addAddressWhitelist({
            name: 'sDAI',
            address:
                TAPIOCA_Z_CONFIG.DEPLOY_CONFIG.POST_LBP[hre.SDK.eChainId]!.sDAI,
            calls,
            cluster,
        });
    }
}

async function addRoleForContract(params: {
    hre: HardhatRuntimeEnvironment;
    cluster: Cluster;
    target: string;
    role: string;
    calls: TapiocaMulticall.CallStruct[];
}) {
    const { hre, cluster, target, calls, role } = params;
    // Role setting not working
    const ROLE = hre.ethers.utils.keccak256(
        hre.ethers.utils.solidityPack(['string'], [role]),
    );

    if (!(await cluster.hasRole(target, ROLE))) {
        console.log(`[+] Adding ${target} to ${role} role`);
        calls.push({
            target: cluster.address,
            callData: cluster.interface.encodeFunctionData(
                'setRoleForContract',
                [target, ROLE, true],
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

async function addMockWhitelist(params: {
    hre: HardhatRuntimeEnvironment;
    tag: string;
    name: string;
    address: string;
    calls: TapiocaMulticall.CallStruct[];
}) {
    const { hre, name, tag, address, calls } = params;
    console.log(`[+] Whitelisting ${address} with ${name} `);
    const mock = await hre.ethers.getContractAt(
        'ERC20Mock',
        loadGlobalContract(
            hre,
            TAPIOCA_PROJECTS_NAME.TapiocaZ,
            hre.SDK.eChainId,
            name,
            tag,
        ).address,
    );
    calls.push({
        allowFailure: false,
        callData: mock.interface.encodeFunctionData('setWhitelist', [
            address,
            true,
        ]),
        target: mock.address,
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
async function _addLocalContract(params: {
    hre: HardhatRuntimeEnvironment;
    name: string;
    tag: string;
    calls: TapiocaMulticall.CallStruct[];
    cluster: Cluster;
}) {
    const { hre, name, tag, calls, cluster } = params;
    await addAddressWhitelist({
        calls,
        cluster,
        name,
        address: loadLocalContract(hre, hre.SDK.eChainId, name, tag).address,
    });
}

async function _setMockWhitelist(params: {
    hre: HardhatRuntimeEnvironment;
    name: string;
    tag: string;
    calls: TapiocaMulticall.CallStruct[];
    cluster: Cluster;
}) {
    const { hre, name, tag, calls, cluster } = params;
    await addAddressWhitelist({
        calls,
        cluster,
        name,
        address: loadLocalContract(hre, hre.SDK.eChainId, name, tag).address,
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
    const pauser = loadLocalContract(
        hre,
        hre.SDK.eChainId,
        DEPLOYMENT_NAMES.PAUSER,
        tag,
    ).address;

    return { cluster, magnetar, pearlmit, yieldbox, pauser };
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
