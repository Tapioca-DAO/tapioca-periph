import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

import { displaySeerCLSoloArgs, nonNullValues } from '../../utils';
import { ARGS_CONFIG } from '../config';
import { SeerCLSolo__factory } from '../../../typechain';

export const __buildGMXOracleArgs = async (
    hre: HardhatRuntimeEnvironment,
    deployerAddr: string,
    logArgs = true,
): Promise<Parameters<SeerCLSolo__factory['deploy']>> => {
    const chainID = await hre.getChainId();
    if (chainID !== hre.SDK.config.EChainID.ARBITRUM) {
        throw '[-] GMX Oracle only available on Arbitrum';
    }

    const args: Parameters<SeerCLSolo__factory['deploy']> = [
        'GMX/USD', // Name
        'GMX/USD', // Symbol
        18, // Decimals
        ARGS_CONFIG[chainID].GMX_ORACLE.GMX_USD_CL_DATA_FEED_ADDRESS, // CL Pool
        1, // Multiply/divide CL
        [deployerAddr], // Guardians
        hre.ethers.utils.formatBytes32String('GMX/USD'), // Description,
        ARGS_CONFIG[chainID].MISC.CL_SEQUENCER, // CL Sequencer
        deployerAddr, // Owner
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
