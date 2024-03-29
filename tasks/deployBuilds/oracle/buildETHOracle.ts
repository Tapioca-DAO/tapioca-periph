import { SeerCLSolo__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';

export const buildETHOracle = async (
    hre: HardhatRuntimeEnvironment,
    owner: string,
): Promise<IDeployerVMAdd<SeerCLSolo__factory>> => {
    console.log('[+] buildETHOracle');
    const chainID = hre.SDK.eChainId;

    const args: Parameters<SeerCLSolo__factory['deploy']> = [
        'ETH/USD', // Name
        'ETH/USD', // Symbol
        18, // Decimals
        {
            _poolChainlink:
                DEPLOY_CONFIG.POST_LBP[chainID]!.WETH_USD_CL_DATA_FEED_ADDRESS, // CL Pool
            _isChainlinkMultiplied: 1, // Multiply/divide Uni
            _inBase: (1e18).toString(), // In base
            stalePeriod: 86400, // CL stale period, 1 day
            guardians: [owner], // Guardians
            _description: hre.ethers.utils.formatBytes32String('ETH/USD'), // Description,
            _sequencerUptimeFeed: hre.ethers.constants.AddressZero, // CL Sequencer
            _admin: owner, // Owner
        },
    ];

    return {
        contract: await hre.ethers.getContractFactory('SeerCLSolo'),
        deploymentName: DEPLOYMENT_NAMES.ETH_ORACLE,
        args,
    };
};
