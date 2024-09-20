import { SDaiOracle__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildZroOracle = async (
    hre: HardhatRuntimeEnvironment,
): Promise<IDeployerVMAdd<SDaiOracle__factory>> => {
    const chainID = hre.SDK.eChainId;

    const args: Parameters<SDaiOracle__factory['deploy']> = [
        DEPLOY_CONFIG.POST_LBP[chainID]!.ZRO_USD_CL_DATA_FEED_ADDRESS, // _sDaiOracle
    ];

    return {
        contract: await hre.ethers.getContractFactory('SDaiOracle'),
        deploymentName: DEPLOYMENT_NAMES.ZRO_ORACLE,
        args,
    };
};
