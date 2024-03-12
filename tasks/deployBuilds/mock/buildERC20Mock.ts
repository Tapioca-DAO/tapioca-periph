import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { ERC20Mock__factory } from '@typechain/index';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildERC20Mock = async (
    hre: HardhatRuntimeEnvironment,
    params: {
        deploymentName: string;
        args: Parameters<ERC20Mock__factory['deploy']>;
    },
): Promise<IDeployerVMAdd<ERC20Mock__factory>> => {
    console.log('[+] buildERC20Mock');

    return {
        contract: await hre.ethers.getContractFactory('ERC20Mock'),
        deploymentName: params.deploymentName,
        args: params.args,
    };
};
