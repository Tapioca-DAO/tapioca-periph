import { DualETHOracle__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildDualETHOracle = async (
    hre: HardhatRuntimeEnvironment,
    owner: string,
): Promise<IDeployerVMAdd<DualETHOracle__factory>> => {
    console.log('[+] buildDualETHOracle');
    const chainID = hre.SDK.eChainId;

    const args: Parameters<DualETHOracle__factory['deploy']> = [
        '0x', // _seerClEthOracle
        '0x', // _seerUniEthOracle
        DEPLOY_CONFIG.MISC[chainID]!.CL_SEQUENCER, // CL Sequencer
        owner, // Owner
    ];

    return {
        contract: await hre.ethers.getContractFactory('DualETHOracle'),
        deploymentName: DEPLOYMENT_NAMES.ETH_SEER_DUAL_ORACLE,
        args,
        dependsOn: [
            {
                deploymentName: DEPLOYMENT_NAMES.ETH_SEER_CL_ORACLE,
                argPosition: 0,
            },
            {
                deploymentName: DEPLOYMENT_NAMES.ETH_SEER_UNI_ORACLE,
                argPosition: 1,
            },
        ],
    };
};
