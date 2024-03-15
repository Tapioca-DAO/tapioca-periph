import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { SeerCLSolo__factory } from '@typechain/index';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildGMXOracle = async (
    hre: HardhatRuntimeEnvironment,
    owner: string,
): Promise<IDeployerVMAdd<SeerCLSolo__factory>> => {
    console.log('[+] buildGMXOracle');

    const chainID = hre.SDK.eChainId;
    if (
        chainID !== hre.SDK.config.EChainID.ARBITRUM &&
        chainID !== hre.SDK.config.EChainID.ARBITRUM_SEPOLIA
    ) {
        throw '[-] GMX Oracle only available on Arbitrum or Arbitrum Sepolia';
    }

    const args: Parameters<SeerCLSolo__factory['deploy']> = [
        'GMX/USD', // Name
        'GMX/USD', // Symbol
        18, // Decimals
        {
            _poolChainlink:
                DEPLOY_CONFIG.POST_LBP[chainID]!.GMX_USD_CL_DATA_FEED_ADDRESS, // CL Pool
            _isChainlinkMultiplied: 1, // Multiply/divide CL
            _inBase: (1e18).toString(), // In base
            stalePeriod: 86400, // CL stale period, 1 day
            guardians: [owner], // Guardians
            _description: hre.ethers.utils.formatBytes32String('GMX/USD'), // Description,
            _sequencerUptimeFeed: DEPLOY_CONFIG.MISC[chainID]!.CL_SEQUENCER, // CL Sequencer
            _admin: owner, // Owner
        },
    ];

    return {
        contract: await hre.ethers.getContractFactory('SeerCLSolo'),
        deploymentName: DEPLOYMENT_NAMES.GMX_ORACLE,
        args,
    };
};
