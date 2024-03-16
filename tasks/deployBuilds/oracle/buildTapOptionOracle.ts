import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';
import { TapOptionOracle__factory } from '@typechain/index';

export const buildTapOptionOracle = async (
    hre: HardhatRuntimeEnvironment,
    tapAddress: string,
    tapWethLp: string,
    owner: string,
): Promise<IDeployerVMAdd<TapOptionOracle__factory>> => {
    console.log('[+] buildTAPOracle');

    const chainID = hre.SDK.eChainId;
    if (
        chainID !== hre.SDK.config.EChainID.ARBITRUM &&
        chainID !== hre.SDK.config.EChainID.ARBITRUM_SEPOLIA
    ) {
        throw '[-] TAP Oracle only available on Arbitrum or Arbitrum Sepolia';
    }

    const args: Parameters<TapOptionOracle__factory['deploy']> = [
        'TAP/USDC', // Name
        'TAP/USDC', // Symbol
        18, // Decimals
        {
            // TODO check if this is correct. Do we need TAP/USDC or TAP/ETH?
            addressInAndOutUni: [
                tapAddress, // TAP
                DEPLOY_CONFIG.MISC[chainID]!.USDC, // USDC
            ],
            _circuitUniswap: [
                tapWethLp,
                DEPLOY_CONFIG.MISC[chainID]!.WETH_USDC_UNIV3_LP,
            ], // LP TAP/USDC
            _circuitUniIsMultiplied: [1, 1], // Multiply/divide Uni
            _twapPeriod: 3600, // TWAP, 1hr
            observationLength: 10, // Observation length that each Uni pool should have
            guardians: [owner], // Owner
            _description: hre.ethers.utils.formatBytes32String('TAP/USDC'), // Description,
            _sequencerUptimeFeed: DEPLOY_CONFIG.MISC[chainID]!.CL_SEQUENCER, // CL Sequencer
            _admin: owner, // Owner
        },
    ];

    return {
        contract: await hre.ethers.getContractFactory('TapOptionOracle'),
        deploymentName: DEPLOYMENT_NAMES.TAP_OPTION_ORACLE,
        args,
    };
};
