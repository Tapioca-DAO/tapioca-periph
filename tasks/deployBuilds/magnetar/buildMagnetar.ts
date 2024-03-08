import { IDependentOn } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { Magnetar__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildMagnetar = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<Magnetar__factory['deploy']>,
    dependsOn: IDependentOn[],
): Promise<IDeployerVMAdd<Magnetar__factory>> => {
    return {
        contract: new Magnetar__factory(hre.ethers.provider.getSigner()),
        deploymentName,
        args,
        dependsOn,
    };
};
