import { ZeroXSwapper__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildZeroXSwapper = async (
    hre: HardhatRuntimeEnvironment,
    args: Parameters<ZeroXSwapper__factory['deploy']>,
): Promise<IDeployerVMAdd<ZeroXSwapper__factory>> => {
    return {
        contract: new ZeroXSwapper__factory(hre.ethers.provider.getSigner()),
        deploymentName: DEPLOYMENT_NAMES.ZERO_X_SWAPPER,
        args,
    };
};
