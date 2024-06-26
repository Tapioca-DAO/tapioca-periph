import { Vault__factory } from '@typechain/index';
import { BigNumberish } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildVault = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: {
        authorizer: string;
        usdc: string;
        pauseWindowDuration: BigNumberish;
        bufferPeriodDuration: BigNumberish;
    },
): Promise<IDeployerVMAdd<Vault__factory>> => {
    const { authorizer, usdc, pauseWindowDuration, bufferPeriodDuration } =
        args;
    return {
        contract: new Vault__factory(hre.ethers.provider.getSigner()),
        deploymentName,
        args: [authorizer, usdc, pauseWindowDuration, bufferPeriodDuration],
        dependsOn: [
            {
                deploymentName: DEPLOYMENT_NAMES.LBP_AUTHORIZER,
                argPosition: 0,
            },
        ],
    };
};
