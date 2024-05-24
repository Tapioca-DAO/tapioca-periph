import { MagnetarHelper__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildMagnetarHelper = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
): Promise<IDeployerVMAdd<MagnetarHelper__factory>> => {
    return {
        contract: new MagnetarHelper__factory(hre.ethers.provider.getSigner()),
        deploymentName,
        args: [],
    };
};
