import { IDependentOn } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { UsdoMarketOracle__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildUsdoMarketOracle = async (
    hre: HardhatRuntimeEnvironment,
    params: {
        deploymentName: string;
        args: Parameters<UsdoMarketOracle__factory['deploy']>;
        dependsOn: IDependentOn[];
    },
): Promise<IDeployerVMAdd<UsdoMarketOracle__factory>> => {
    console.log(`[+] Building ${params.deploymentName}`);

    return {
        contract: new UsdoMarketOracle__factory().connect(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName: params.deploymentName,
        args: params.args,
        dependsOn: params.dependsOn,
    };
};
