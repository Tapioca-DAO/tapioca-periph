import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

import { displaySeerCLSoloArgs, nonNullValues } from '../../utils';
import { ARGS_CONFIG } from '../CONF';
import { SeerCLSolo__factory } from '../../../typechain';

export const buildDaiOracle = async (
    hre: HardhatRuntimeEnvironment,
): Promise<IDeployerVMAdd<SeerCLSolo__factory>> => {
    console.log('[+] buildDaiOracle');

    const chainID = await hre.getChainId();
    if (chainID !== hre.SDK.config.EChainID.MAINNET) {
        throw '[-] DAI Oracle only available on Ethereum';
    }
    const deployer = (await hre.ethers.getSigners())[0];

    const args: Parameters<SeerCLSolo__factory['deploy']> = [
        'DAI/USD', // Name
        'DAI/USD', // Symbol
        18, // Decimals
        ARGS_CONFIG[chainID].DAI_ORACLE.DAI_USD_CL_DATA_FEED_ADDRESS, // CL Pool
        1, // Multiply/divide Uni
        86400, // CL stale period, 1 day
        [deployer.address], // Guardians
        hre.ethers.utils.formatBytes32String('DAI/USD'), // Description,
        hre.ethers.constants.AddressZero, // CL Sequencer
        deployer.address, // Owner
    ];

    // Check for null values
    displaySeerCLSoloArgs(args);
    nonNullValues(args);

    return {
        contract: await hre.ethers.getContractFactory('SeerCLSolo'),
        deploymentName: 'DaiOracle',
        args,
    };
};
