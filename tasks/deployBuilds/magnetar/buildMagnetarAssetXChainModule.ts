import { MagnetarAssetXChainModule__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildMagnetarAssetXChainModule = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<MagnetarAssetXChainModule__factory['deploy']>,
): Promise<IDeployerVMAdd<MagnetarAssetXChainModule__factory>> => {
    return {
        contract: new MagnetarAssetXChainModule__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args,
        dependsOn: [],
    };
};
