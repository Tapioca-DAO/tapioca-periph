import { IDependentOn } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { MagnetarMintModule__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildMagnetarMintModule = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<MagnetarMintModule__factory['deploy']>,
): Promise<IDeployerVMAdd<MagnetarMintModule__factory>> => {
    return {
        contract: new MagnetarMintModule__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args,
    };
};
