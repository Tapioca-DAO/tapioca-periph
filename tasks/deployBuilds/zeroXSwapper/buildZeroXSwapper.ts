import { ZeroXSwapper__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildZeroXSwapper = async (
    hre: HardhatRuntimeEnvironment,
    tag: string,
    owner: string,
): Promise<IDeployerVMAdd<ZeroXSwapper__factory>> => {
    const args: Parameters<ZeroXSwapper__factory['deploy']> = [
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.ZERO_X_PROXY,
        hre.ethers.constants.AddressZero, // clusterAddr
        owner,
    ];
    return {
        contract: new ZeroXSwapper__factory(hre.ethers.provider.getSigner()),
        deploymentName: DEPLOYMENT_NAMES.ZERO_X_SWAPPER,
        args,
        dependsOn: [
            {
                deploymentName: DEPLOYMENT_NAMES.CLUSTER,
                argPosition: 1,
            },
        ],
    };
};
