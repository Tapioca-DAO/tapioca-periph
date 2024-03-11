import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

import { displaySeerCLSoloArgs, nonNullValues } from '../../utils';
import { SeerCLSolo__factory } from '@typechain/index';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const __buildETHOracleArgs = async (
    hre: HardhatRuntimeEnvironment,
    deployerAddr: string,
): Promise<Parameters<SeerCLSolo__factory['deploy']>> => {
    const chainID = hre.SDK.eChainId;
    if (chainID !== hre.SDK.config.EChainID.ARBITRUM) {
        throw '[-] ETH mainnet Oracle only available on Arbitrum';
    }

    const args: Parameters<SeerCLSolo__factory['deploy']> = [
        'ETH/USD', // Name
        'ETH/USD', // Symbol
        18, // Decimals
        {
            _poolChainlink:
                DEPLOY_CONFIG.PRE_LBP[chainID]!.WETH_USD_CL_DATA_FEED_ADDRESS, // CL Pool
            _isChainlinkMultiplied: 1, // Multiply/divide Uni
            _inBase: (1e18).toString(), // In base
            stalePeriod: 86400, // CL stale period, 1 day
            guardians: [deployerAddr], // Guardians
            _description: hre.ethers.utils.formatBytes32String('ETH/USD'), // Description,
            _sequencerUptimeFeed: hre.ethers.constants.AddressZero, // CL Sequencer
            _admin: deployerAddr, // Owner
        },
    ];

    // Check for null values
    nonNullValues(args);

    return args;
};

export const buildETHOracle = async (
    hre: HardhatRuntimeEnvironment,
): Promise<IDeployerVMAdd<SeerCLSolo__factory>> => {
    console.log('[+] buildETHOracle');
    const deployer = (await hre.ethers.getSigners())[0];

    const args = await __buildETHOracleArgs(hre, deployer.address);

    displaySeerCLSoloArgs(args);

    return {
        contract: await hre.ethers.getContractFactory('SeerCLSolo'),
        deploymentName: 'ETHOracle__Arbitrum',
        args,
    };
};
