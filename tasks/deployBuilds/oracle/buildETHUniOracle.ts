import { Seer__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildETHUniOracle = async (
    hre: HardhatRuntimeEnvironment,
    owner: string,
    isTestnet: boolean,
): Promise<IDeployerVMAdd<Seer__factory>> => {
    const chainID = hre.SDK.eChainId;

    const args: Parameters<Seer__factory['deploy']> = [
        'UniV3 ETH/USD', // Name
        'ETH/USD', // Symbol
        18, // Decimals
        {
            addressInAndOutUni: [
                DEPLOY_CONFIG.MISC[chainID]!.WETH,
                DEPLOY_CONFIG.MISC[chainID]!.USDC,
            ],
            _circuitUniswap: [DEPLOY_CONFIG.MISC[chainID]!.WETH_USDC_UNIV3_LP], // LP ETH/USDC
            _circuitUniIsMultiplied: [1], // Multiply/divide Uni
            _twapPeriod: isTestnet ? 1 : 3600, // TWAP, 1hr
            observationLength: isTestnet ? 1 : 10, // Observation length that each Uni pool should have
            _uniFinalCurrency: 1, // Whether we need to use the last Chainlink oracle to convert to another
            _circuitChainlink: [
                DEPLOY_CONFIG.POST_LBP[chainID]!.USDC_USD_CL_DATA_FEED_ADDRESS,
            ], // CL path
            _circuitChainIsMultiplied: [1], // Multiply/divide CL
            guardians: [owner], // Owner
            _description: hre.ethers.utils.formatBytes32String('ETH/USD'), // Description,
            _sequencerUptimeFeed: DEPLOY_CONFIG.MISC[chainID]!.CL_SEQUENCER, // CL Sequencer
            _admin: owner, // Owner
        },
    ];

    return {
        contract: await hre.ethers.getContractFactory('Seer'),
        deploymentName: DEPLOYMENT_NAMES.ETH_SEER_UNI_ORACLE,
        args,
    };
};
