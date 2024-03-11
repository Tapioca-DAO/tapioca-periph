import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { displaySeerArgs, nonNullValues } from '../../utils';
import { Seer__factory } from '@typechain/index';
import { DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildTapOracle = async (
    hre: HardhatRuntimeEnvironment,
    tapAddress: string,
    ltapUsdcAddress: string,
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
        {
            addressInAndOutUni: [
                tapAddress, // TAP
                DEPLOY_CONFIG.MISC[chainID]!.USDC, // USDC
            ],
            _circuitUniswap: [ltapUsdcAddress], // LP TAP/USDC
            _circuitUniIsMultiplied: [1], // Multiply/divide Uni
            _twapPeriod: 3600, // TWAP, 1hr
            observationLength: 10, // Observation length that each Uni pool should have
            _uniFinalCurrency: 0, // Whether we need to use the last Chainlink oracle to convert to another
            _circuitChainlink: [], // CL path
            _circuitChainIsMultiplied: [], // Multiply/divide CL
            _stalePeriod: 86400, // CL period before stale, 1 day
            guardians: [deployer.address], // Owner
            _description: hre.ethers.utils.formatBytes32String('TAP/USDC'), // Description,
            _sequencerUptimeFeed: DEPLOY_CONFIG.MISC[chainID]!.CL_SEQUENCER, // CL Sequencer
            _admin: deployer.address, // Owner
        },
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
