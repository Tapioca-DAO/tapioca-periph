import { Seer__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildUsdoUsdcOracle = async (params: {
    hre: HardhatRuntimeEnvironment;
    owner: string;
    usdoAddy: string;
    usdoUsdcLpAddy: string;
    isTestnet: boolean;
}): Promise<IDeployerVMAdd<Seer__factory>> => {
    const { hre, owner, usdoAddy, usdoUsdcLpAddy, isTestnet } = params;
    const chainID = hre.SDK.eChainId;

    const args: Parameters<Seer__factory['deploy']> = [
        'USDO->USDC->USD', // Name
        'USDO/USD', // Symbol
        18, // Decimals
        {
            addressInAndOutUni: [usdoAddy, DEPLOY_CONFIG.MISC[chainID]!.USDC],
            _circuitUniswap: [usdoUsdcLpAddy], // LP ETH/USDC
            _circuitUniIsMultiplied: [1], // Multiply/divide Uni
            _twapPeriod: isTestnet ? 1 : 3600, // TWAP, 1hr
            observationLength: isTestnet ? 1 : 10, // Observation length that each Uni pool should have
            _uniFinalCurrency: 1, // Whether we need to use the last Chainlink oracle to convert to another
            _circuitChainlink: [
                DEPLOY_CONFIG.POST_LBP[chainID]!.USDC_USD_CL_DATA_FEED_ADDRESS,
            ], // CL path
            _circuitChainIsMultiplied: [1], // Multiply/divide CL
            guardians: [owner], // Owner
            _description:
                hre.ethers.utils.formatBytes32String('USDO->USDC->USD'), // Description,
            _sequencerUptimeFeed: DEPLOY_CONFIG.MISC[chainID]!.CL_SEQUENCER, // CL Sequencer
            _admin: owner, // Owner
        },
    ];

    return {
        contract: await hre.ethers.getContractFactory('Seer'),
        deploymentName: DEPLOYMENT_NAMES.USDO_USDC_UNI_V3_ORACLE,
        args,
    };
};
