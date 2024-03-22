import { MagnetarYieldBoxModule__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildYieldboxModule = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<MagnetarYieldBoxModule__factory['deploy']>,
): Promise<IDeployerVMAdd<MagnetarYieldBoxModule__factory>> => {
    return {
        contract: new MagnetarYieldBoxModule__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args,
        dependsOn: [],
    };
};
