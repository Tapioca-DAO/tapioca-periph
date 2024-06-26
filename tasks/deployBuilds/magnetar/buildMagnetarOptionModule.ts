import { IDependentOn } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { MagnetarOptionModule__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildMagnetarOptionModule = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<MagnetarOptionModule__factory['deploy']>,
): Promise<IDeployerVMAdd<MagnetarOptionModule__factory>> => {
    return {
        contract: new MagnetarOptionModule__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args,
    };
};
