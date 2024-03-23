import { MagnetarBaseModuleExternal__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildMagnetarBaseModuleExternal = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<MagnetarBaseModuleExternal__factory['deploy']>,
): Promise<IDeployerVMAdd<MagnetarBaseModuleExternal__factory>> => {
    return {
        contract: new MagnetarBaseModuleExternal__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args,
        dependsOn: [],
    };
};
