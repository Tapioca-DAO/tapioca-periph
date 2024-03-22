import { MagnetarCollateralModule__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildMagnetarCollateralModule = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<MagnetarCollateralModule__factory['deploy']>,
): Promise<IDeployerVMAdd<MagnetarCollateralModule__factory>> => {
    return {
        contract: new MagnetarCollateralModule__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args,
        dependsOn: [],
    };
};
