import { IDependentOn } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { MagnetarMintXChainModule__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildMagnetarMintXChainModule = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<MagnetarMintXChainModule__factory['deploy']>,
    dependsOn: IDependentOn[],
): Promise<IDeployerVMAdd<MagnetarMintXChainModule__factory>> => {
    return {
        contract: new MagnetarMintXChainModule__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args,
        dependsOn,
    };
};
