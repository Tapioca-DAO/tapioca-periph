import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from './DEPLOY_CONFIG';
import { TapiocaMulticall } from '@typechain/index';

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

    console.log('[+] Deploy final task');

    const { cluster, magnetar } =
        await deployPostLbpStack__loadContracts__generic(hre, taskArgs.tag);

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

    const TOE_ROLE = hre.ethers.utils.keccak256('TOE'); // Role to be able to use TOE.sendPacketFrom()
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

    return { cluster, magnetar };
}
