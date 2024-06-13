import { IDependentOn } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { Pauser__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildPauserManager = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<Pauser__factory['deploy']>,
    dependsOn: IDependentOn[],
): Promise<IDeployerVMAdd<Pauser__factory>> => {
    return {
        contract: new Pauser__factory(hre.ethers.provider.getSigner()),
        deploymentName,
        args,
        dependsOn,
    };
};
