import { SeerCLMulti__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildRethUsdOracle = async (
    hre: HardhatRuntimeEnvironment,
    owner: string,
    isTestnet: boolean,
): Promise<IDeployerVMAdd<SeerCLMulti__factory>> => {
    console.log('[+] buildReth/UsdOracle');
    const chainID = hre.SDK.eChainId;

    const args: Parameters<SeerCLMulti__factory['deploy']> = [
        'RETH/ETH -> ETH/USD', // Name
        'RETH/USD', // Symbol
        18, // Decimals
        {
            _circuitChainlink: [
                DEPLOY_CONFIG.POST_LBP[chainID]!.RETH_ETH_CL_DATA_FEED_ADDRESS,
                DEPLOY_CONFIG.POST_LBP[chainID]!.WETH_USD_CL_DATA_FEED_ADDRESS,
            ], // CL Pool
            _circuitChainIsMultiplied: [1, 1], // Multiply/divide Uni
            _inBase: (1e18).toString(), // In base
            stalePeriod: isTestnet ? 4294967295 : 86400, // CL stale period, 1 day on prod. max uint32 on testnet
            guardians: [owner], // Guardians
            _description: hre.ethers.utils.formatBytes32String(
                'RETH/ETH -> ETH/USD',
            ), // Description,
            _sequencerUptimeFeed: hre.ethers.constants.AddressZero, // CL Sequencer
            _admin: owner, // Owner
        },
    ];

    return {
        contract: await hre.ethers.getContractFactory('SeerCLMulti'),
        deploymentName: DEPLOYMENT_NAMES.RETH_USD_SEER_CL_MULTI_ORACLE,
        args,
    };
};
