import { Authorizer__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildAuthorizer = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: { admin: string },
): Promise<IDeployerVMAdd<Authorizer__factory>> => {
    const { admin } = args;
    return {
        contract: new Authorizer__factory(hre.ethers.provider.getSigner()),
        deploymentName,
        args: [admin],
        dependsOn: [],
    };
};
