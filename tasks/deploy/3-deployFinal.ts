import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract, loadLocalContract } from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from './DEPLOY_CONFIG';
import { TapiocaMulticall } from '@typechain/index';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import * as TAPIOCA_BAR_CONFIG from '@tapioca-bar/config';

/**
 * @notice Cluster whitelist
 */
export const deployFinal__task = async (
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

async function postDeployTask(params: TTapiocaDeployerVmPass<unknown>) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, chainInfo, isTestnet } =
        params;
    const { tag } = taskArgs;

    console.log('[+] Deploy final task');

    const { cluster, magnetar, pearlmit } =
        await deployPostLbpStack__loadContracts__generic(hre, tag);

    const calls: TapiocaMulticall.CallStruct[] = [];

    const addAddressWhitelist = async (name: string, address: string) => {
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
    };

    await addAddressWhitelist('Magnetar', magnetar.address);
    await addAddressWhitelist('Pearlmit', pearlmit);

    // Role setting not working
    const TOE_ROLE = hre.ethers.utils.keccak256(
        hre.ethers.utils.solidityPack(['string'], ['TOE']),
    ); // Role to be able to use TOE.sendPacketFrom()

    if (!(await cluster.hasRole(magnetar.address, TOE_ROLE))) {
        console.log(`[+] Adding Magnetar ${magnetar.address} to TOE role`);
        calls.push({
            target: cluster.address,
            callData: cluster.interface.encodeFunctionData(
                'setRoleForContract',
                [magnetar.address, TOE_ROLE, true],
            ),
            allowFailure: false,
        });
    }
    const addBarContract = async (name: string) => {
        await addAddressWhitelist(
            name,
            loadGlobalContract(
                hre,
                TAPIOCA_PROJECTS_NAME.TapiocaBar,
                hre.SDK.eChainId,
                name,
                tag,
            ).address,
        );
    };

    if (
        hre.SDK.chainInfo.name === 'arbitrum' ||
        hre.SDK.chainInfo.name === 'arbitrum_sepolia'
    ) {
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
    }

    if (
        hre.SDK.chainInfo.name === 'ethereum' ||
        hre.SDK.chainInfo.name === 'sepolia' ||
        hre.SDK.chainInfo.name === 'optimism_sepolia'
    ) {
        await addBarContract(
            TAPIOCA_BAR_CONFIG.DEPLOYMENT_NAMES.SGL_S_DAI_MARKET,
        );
    }

    await VM.executeMulticall(calls);
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

    return { cluster, magnetar, pearlmit };
}
