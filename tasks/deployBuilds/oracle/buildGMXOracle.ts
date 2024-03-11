import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

import { displaySeerCLSoloArgs, nonNullValues } from '../../utils';
import { SeerCLSolo__factory } from '@typechain/index';
import { DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const __buildGMXOracleArgs = async (
    hre: HardhatRuntimeEnvironment,
    deployerAddr: string,
    logArgs = true,
): Promise<Parameters<SeerCLSolo__factory['deploy']>> => {
    const chainID = hre.SDK.eChainId;
    if (chainID !== hre.SDK.config.EChainID.ARBITRUM) {
        throw '[-] GMX Oracle only available on Arbitrum';
    }

    const args: Parameters<SeerCLSolo__factory['deploy']> = [
        'GMX/USD', // Name
        'GMX/USD', // Symbol
        18, // Decimals
        {
            _poolChainlink:
                DEPLOY_CONFIG.PRE_LBP[chainID]!.GMX_USD_CL_DATA_FEED_ADDRESS, // CL Pool
            _isChainlinkMultiplied: 1, // Multiply/divide CL
            _inBase: (1e18).toString(), // In base
            stalePeriod: 86400, // CL stale period, 1 day
            guardians: [deployerAddr], // Guardians
            _description: hre.ethers.utils.formatBytes32String('GMX/USD'), // Description,
            _sequencerUptimeFeed: DEPLOY_CONFIG.MISC[chainID]!.CL_SEQUENCER, // CL Sequencer
            _admin: deployerAddr, // Owner
        },
    ];

    // Check for null values
    if (logArgs) displaySeerCLSoloArgs(args);
    nonNullValues(args);

    return args;
};

export const buildGMXOracle = async (
    hre: HardhatRuntimeEnvironment,
): Promise<IDeployerVMAdd<SeerCLSolo__factory>> => {
    console.log('[+] buildGMXOracle');

    const deployer = (await hre.ethers.getSigners())[0];
    const args = await __buildGMXOracleArgs(hre, deployer.address);

    return {
        contract: await hre.ethers.getContractFactory('SeerCLSolo'),
        deploymentName: 'GMXOracle',
        args,
    };
};
