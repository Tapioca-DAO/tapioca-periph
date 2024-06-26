import { TTapiocaDeployTaskArgs } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { TapiocaMulticall } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const misc__clusterSetRole__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        role: string;
        target: string;
        removeRole: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    const { tag, role, target, removeRole } = _taskArgs;
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });

    const clusterContract = await hre.ethers.getContractAt(
        'Cluster',
        loadLocalContract(
            hre,
            hre.SDK.chainInfo.chainId,
            DEPLOYMENT_NAMES.CLUSTER,
            tag,
        ).address,
    );

    const calls: TapiocaMulticall.CallStruct[] = [];

    calls.push({
        target: clusterContract.address,
        callData: clusterContract.interface.encodeFunctionData(
            'setRoleForContract',
            [
                target,
                hre.ethers.utils.keccak256(
                    hre.ethers.utils.solidityPack(['string'], [role]),
                ),
                removeRole ? false : true,
            ],
        ),
        allowFailure: false,
    });

    await VM.executeMulticall(calls);
};
