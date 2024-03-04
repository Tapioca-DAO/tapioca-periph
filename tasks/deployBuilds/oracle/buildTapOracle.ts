import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { Seer__factory } from '../../../typechain';
import { displaySeerArgs, nonNullValues } from '../../utils';
import { ARGS_CONFIG } from '../../deploy/CONF';

export const buildTapOracle = async (
    hre: HardhatRuntimeEnvironment,
): Promise<IDeployerVMAdd<Seer__factory>> => {
    console.log('[+] buildTAPOracle');

    const chainID = hre.SDK.eChainId;
    if (chainID !== hre.SDK.config.EChainID.ARBITRUM) {
        throw '[-] TAP Oracle only available on Arbitrum';
    }
    const deployer = (await hre.ethers.getSigners())[0];

    const args: Parameters<Seer__factory['deploy']> = [
        'TAP/USDC', // Name
        'TAP/USDC', // Symbol
        18, // Decimals
        [
            ARGS_CONFIG[chainID].TAP_ORACLE.TAP_ADDRESS, // TAP
            ARGS_CONFIG[chainID].MISC.USDC_ADDRESS, // USDC
        ],
        [
            ARGS_CONFIG[chainID].TAP_ORACLE.TAP_USDC_LP_ADDRESS, /// LP TAP/USDC
        ],
        [1], // Multiply/divide Uni
        3600, // TWAP, 1hr
        10, // Observation length that each Uni pool should have
        0, // Whether we need to use the last Chainlink oracle to convert to another
        // CL path
        [],
        [], // Multiply/divide CL
        86400, // CL period before stale, 1 day
        [deployer.address], // Owner
        hre.ethers.utils.formatBytes32String('TAP/USDC'), // Description,
        ARGS_CONFIG[chainID].MISC.CL_SEQUENCER, // CL Sequencer
        deployer.address, // Owner
    ];

    // Check for null values
    displaySeerArgs(args);
    nonNullValues(args);

    return {
        contract: await hre.ethers.getContractFactory('Seer'),
        deploymentName: 'TapOracle',
        args,
    };
};
