import { Cluster__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildCluster = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<Cluster__factory['deploy']>,
): Promise<IDeployerVMAdd<Cluster__factory>> => {
    return {
        contract: new Cluster__factory(hre.ethers.provider.getSigner()),
        deploymentName,
        args,
        dependsOn: [],
    };
};
