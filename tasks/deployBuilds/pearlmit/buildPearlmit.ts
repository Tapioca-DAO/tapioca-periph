import { Pearlmit__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildPearlmit = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<Pearlmit__factory['deploy']>,
): Promise<IDeployerVMAdd<Pearlmit__factory>> => {
    return {
        contract: new Pearlmit__factory(hre.ethers.provider.getSigner()),
        deploymentName,
        args,
        dependsOn: [],
    };
};
