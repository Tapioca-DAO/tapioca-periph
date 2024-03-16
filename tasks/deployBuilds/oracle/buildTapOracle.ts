import { Seer__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildTapOracle = async (
    hre: HardhatRuntimeEnvironment,
    tapAddress: string,
    tapWethLpPair: string,
    owner: string,
): Promise<IDeployerVMAdd<Seer__factory>> => {
    console.log('[+] buildTAPOracle');

    const chainID = hre.SDK.eChainId;
    if (
        chainID !== hre.SDK.config.EChainID.ARBITRUM &&
        chainID !== hre.SDK.config.EChainID.ARBITRUM_SEPOLIA
    ) {
        throw '[-] TAP Oracle only available on Arbitrum or Arbitrum Sepolia';
    }

    const args: Parameters<Seer__factory['deploy']> = [
        'TAP/USD', // Name
        'TAP/USD', // Symbol
        18, // Decimals
        {
            addressInAndOutUni: [
                tapAddress, // TAP
                DEPLOY_CONFIG.MISC[chainID]!.WETH,
            ],
            _circuitUniswap: [tapWethLpPair], // LP TAP/WETH
            _circuitUniIsMultiplied: [1], // Multiply/divide Uni
            _twapPeriod: 3600, // TWAP, 1hr
            observationLength: 10, // Observation length that each Uni pool should have
            _uniFinalCurrency: 0, // Whether we need to use the last Chainlink oracle to convert to another
            _circuitChainlink: [
                DEPLOY_CONFIG.POST_LBP[chainID]!.WETH_USD_CL_DATA_FEED_ADDRESS,
            ], // CL path
            _circuitChainIsMultiplied: [1], // Multiply/divide CL
            _stalePeriod: 86400, // CL period before stale, 1 day
            guardians: [owner], // Owner
            _description: hre.ethers.utils.formatBytes32String('TAP/USDC'), // Description,
            _sequencerUptimeFeed: DEPLOY_CONFIG.MISC[chainID]!.CL_SEQUENCER, // CL Sequencer
            _admin: owner, // Owner
        },
    ];

    return {
        contract: await hre.ethers.getContractFactory('Seer'),
        deploymentName: DEPLOYMENT_NAMES.TAP_ORACLE,
        args,
    };
};
