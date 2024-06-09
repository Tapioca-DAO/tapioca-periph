import { BalancerQueries__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildBalancerQueries = async (
    hre: HardhatRuntimeEnvironment,
): Promise<IDeployerVMAdd<BalancerQueries__factory>> => {
    return {
        contract: new BalancerQueries__factory(hre.ethers.provider.getSigner()),
        deploymentName: DEPLOYMENT_NAMES.LBP_BALANCER_QUERIES,
        args: [
            '', // LBP vault
        ],
        dependsOn: [
            {
                deploymentName: DEPLOYMENT_NAMES.LBP_VAULT,
                argPosition: 0,
            },
        ],
    };
};
