import { GLPManagerMock__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildGLPManagerMock = async (
    hre: HardhatRuntimeEnvironment,
    params: {
        deploymentName: string;
        args: Parameters<GLPManagerMock__factory['deploy']>;
    },
): Promise<IDeployerVMAdd<GLPManagerMock__factory>> => {
    console.log('[+] buildGLPManagerMock');

    return {
        contract: await hre.ethers.getContractFactory('GLPManagerMock'),
        deploymentName: params.deploymentName,
        args: params.args,
        meta: {
            glpPrice: params.args[0],
        },
    };
};
