import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { EthGlpOracle__factory } from '@typechain/index';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildEthGlpPOracle = async (
    hre: HardhatRuntimeEnvironment,
    owner: string,
): Promise<IDeployerVMAdd<EthGlpOracle__factory>> => {
    console.log('[+] buildEthGlpOracle');

    const chainID = hre.SDK.eChainId;
    if (
        chainID !== hre.SDK.config.EChainID.ARBITRUM &&
        chainID !== hre.SDK.config.EChainID.ARBITRUM_SEPOLIA
    ) {
        throw '[-] EthGlp Oracle only available on Arbitrum or Arbitrum Sepolia';
    }

    const args: Parameters<EthGlpOracle__factory['deploy']> = [
        hre.ethers.constants.AddressZero, // wethUsdOracle
        hre.ethers.constants.AddressZero, // glpUsdOracle
        owner, // Owner
    ];

    return {
        contract: await hre.ethers.getContractFactory('EthGlpOracle'),
        deploymentName: DEPLOYMENT_NAMES.ETH_GLP_ORACLE,
        args,
        dependsOn: [
            {
                deploymentName: DEPLOYMENT_NAMES.ETH_SEER_CL_ORACLE,
                argPosition: 0,
            },
            {
                deploymentName: DEPLOYMENT_NAMES.GLP_ORACLE,
                argPosition: 1,
            },
        ],
    };
};
