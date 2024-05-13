import { OracleMock__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildOracleMock = async (
    hre: HardhatRuntimeEnvironment,
    params: {
        deploymentName: string;
        args: Parameters<OracleMock__factory['deploy']>;
    },
): Promise<IDeployerVMAdd<OracleMock__factory>> => {
    console.log('[+] buildOracleMock');

    return {
        contract: new OracleMock__factory().connect(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName: params.deploymentName,
        args: params.args,
    };
};
