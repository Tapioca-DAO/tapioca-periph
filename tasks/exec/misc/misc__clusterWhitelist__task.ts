import { TTapiocaDeployTaskArgs } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { TapiocaMulticall } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const misc__clusterWhitelist__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        cluster?: string;
        targets: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    const { tag, cluster, targets } = _taskArgs;
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });

    const clusterContract = await hre.ethers.getContractAt(
        'Cluster',
        cluster ??
            loadLocalContract(
                hre,
                hre.SDK.chainInfo.chainId,
                DEPLOYMENT_NAMES.CLUSTER,
                tag,
            ).address,
    );

    const calls: TapiocaMulticall.CallStruct[] = [];

    const addresses = targets.split(',');

    for (const target of addresses) {
        if (!(await clusterContract.isWhitelisted(0, target))) {
            console.log(`[+] Whitelisting ${target}`);
            calls.push({
                target: clusterContract.address,
                callData: clusterContract.interface.encodeFunctionData(
                    'updateContract',
                    [0, target, true],
                ),
                allowFailure: false,
            });
        } else {
            console.log(`[+] ${target} already whitelisted`);
        }
    }
    await VM.executeMulticall(calls);
};
