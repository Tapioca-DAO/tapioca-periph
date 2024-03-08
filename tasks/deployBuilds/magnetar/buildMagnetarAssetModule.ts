import { MagnetarAssetModule__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildMagnetarAssetModule = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<MagnetarAssetModule__factory['deploy']>,
): Promise<IDeployerVMAdd<MagnetarAssetModule__factory>> => {
    return {
        contract: new MagnetarAssetModule__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args,
        dependsOn: [],
    };
};
