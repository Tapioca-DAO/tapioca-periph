import { IDependentOn } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { ZeroXSwapperMock__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildZeroXSwapperMock = async (
    hre: HardhatRuntimeEnvironment,
    args: Parameters<ZeroXSwapperMock__factory['deploy']>,
    dependsOn: IDependentOn[],
): Promise<IDeployerVMAdd<ZeroXSwapperMock__factory>> => {
    console.log('\t[+] Building ZeroXSwapperMock...');
    return {
        contract: new ZeroXSwapperMock__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName: DEPLOYMENT_NAMES.ZERO_X_SWAPPER_MOCK,
        args,
        dependsOn,
    };
};
