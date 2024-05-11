import { TapiocaOmnichainEngineHelper__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildTOEHelper = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: Parameters<TapiocaOmnichainEngineHelper__factory['deploy']>,
): Promise<IDeployerVMAdd<TapiocaOmnichainEngineHelper__factory>> => {
    return {
        contract: new TapiocaOmnichainEngineHelper__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args,
        dependsOn: [],
    };
};
