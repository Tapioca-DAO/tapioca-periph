import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildYieldBox } from 'tasks/deployBuilds/yieldbox/buildYieldbox';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from './DEPLOY_CONFIG';

/**
 * @notice First thing to deploy
 *
 * Deploys:
 * - YieldBox
 *
 */
export const deployPreLbpYieldbox = async (
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
