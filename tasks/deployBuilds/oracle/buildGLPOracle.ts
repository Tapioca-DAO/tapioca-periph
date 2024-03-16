import { GLPOracle__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildGLPOracle = async (
    hre: HardhatRuntimeEnvironment,
    owner: string,
): Promise<IDeployerVMAdd<GLPOracle__factory>> => {
    console.log('[+] buildGLPOracle');

    const chainID = hre.SDK.eChainId;
    if (
        chainID !== hre.SDK.config.EChainID.ARBITRUM &&
        chainID !== hre.SDK.config.EChainID.ARBITRUM_SEPOLIA
    ) {
        throw '[-] GLP Oracle only available on Arbitrum or Arbitrum Sepolia';
    }

    const args: Parameters<GLPOracle__factory['deploy']> = [
        DEPLOY_CONFIG.POST_LBP[chainID]!.GLP_MANAGER,
        DEPLOY_CONFIG.MISC[chainID]!.CL_SEQUENCER,
        owner, // Owner
    ];

    return {
        contract: await hre.ethers.getContractFactory('GLPOracle'),
        deploymentName: DEPLOYMENT_NAMES.GLP_ORACLE,
        args,
    };
};
