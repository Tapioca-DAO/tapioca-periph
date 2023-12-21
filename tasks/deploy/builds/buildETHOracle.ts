import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

import { displaySeerCLSoloArgs, nonNullValues } from '../../utils';
import { ARGS_CONFIG } from '../CONF';
import { SeerCLSolo__factory } from '../../../typechain';

export const __buildETHOracleArgs = async (
    hre: HardhatRuntimeEnvironment,
    deployerAddr: string,
): Promise<Parameters<SeerCLSolo__factory['deploy']>> => {
    const chainID = await hre.getChainId();
    if (chainID !== hre.SDK.config.EChainID.ARBITRUM) {
        throw '[-] ETH mainnet Oracle only available on Arbitrum';
    }

    const args: Parameters<SeerCLSolo__factory['deploy']> = [
        'ETH/USD', // Name
        'ETH/USD', // Symbol
        18, // Decimals
        ARGS_CONFIG[chainID].WETH_ORACLE.WETH_USD_CL_DATA_FEED_ADDRESS, // CL Pool
        1, // Multiply/divide Uni
        86400, // CL stale period, 1 day
        [deployerAddr], // Guardians
        hre.ethers.utils.formatBytes32String('ETH/USD'), // Description,
        hre.ethers.constants.AddressZero, // CL Sequencer
        deployerAddr, // Owner
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
