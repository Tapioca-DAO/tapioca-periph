import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildYieldBox } from 'tasks/deployBuilds/yieldbox/buildYieldbox';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from './DEPLOY_CONFIG';
import { buildPearlmit } from 'tasks/deployBuilds/pearlmit/buildPearlmit';
import { buildCluster } from 'tasks/deployBuilds/cluster/buildCluster';

/**
 * @notice First thing to deploy
 *
 * Deploys:
 * - YieldBox
 * - Cluster
 * - Pearlmit
 */
export const deployAirdrop__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        {
            hre,
        },
        async ({
            VM,
            tapiocaMulticallAddr,
            chainInfo,
            taskArgs,
            isTestnet,
        }) => {
            const { tag } = taskArgs;

            // VM.add(
            //     await buildPearlmit(hre, DEPLOYMENT_NAMES.PEARLMIT, [
            //         DEPLOYMENT_NAMES.PEARLMIT,
            //         '1',
            //         tapiocaMulticallAddr,
            //         0,
            //     ]),
            // ).add(
            //     await buildCluster(hre, DEPLOYMENT_NAMES.CLUSTER, [
            //         chainInfo.lzChainId,
            //         tapiocaMulticallAddr,
            //     ]),
            // );

            const pearlmit = loadLocalContract(
                hre,
                hre.SDK.chainInfo.chainId,
                DEPLOYMENT_NAMES.PEARLMIT,
                tag,
            );

            const [ybURI, yieldBox] = await buildYieldBox(
                hre,
                DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.WETH!,
                pearlmit.address,
                tapiocaMulticallAddr,
            );

            VM.add(ybURI).add(yieldBox);
        },
    );
};
