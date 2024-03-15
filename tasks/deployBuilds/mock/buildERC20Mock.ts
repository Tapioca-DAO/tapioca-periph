import { ERC20Mock__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildERC20Mock = async (
    hre: HardhatRuntimeEnvironment,
    params: {
        deploymentName: string;
        args: Parameters<ERC20Mock__factory['deploy']>;
    },
): Promise<IDeployerVMAdd<ERC20Mock__factory>> => {
    console.log('[+] buildERC20Mock');

    return {
        contract: new ERC20Mock__factory().connect(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName: params.deploymentName,
        args: params.args,
    };
};
