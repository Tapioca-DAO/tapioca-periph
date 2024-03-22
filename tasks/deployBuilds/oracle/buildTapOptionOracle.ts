import { TapOptionOracle__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';
import { getTapOracleMultiDeployParams } from './buildTapOracle';

export async function buildTOBTapOptionOracle(
    hre: HardhatRuntimeEnvironment,
    tapAddress: string,
    tapWethLp: string,
    owner: string,
) {
    console.log('[+] buildTOB_TAPOptionOracle');
    return await buildTapOptionOracle(
        hre,
        'TOB_TAP_OPTION_ORACLE',
        tapAddress,
        tapWethLp,
        owner,
        14400, // 4 hours
    );
}

export async function buildADBTapOptionOracle(
    hre: HardhatRuntimeEnvironment,
    tapAddress: string,
    tapWethLp: string,
    owner: string,
) {
    console.log('[+] buildADB_TAPOptionOracle');
    return await buildTapOptionOracle(
        hre,
        'ADB_TAP_OPTION_ORACLE',
        tapAddress,
        tapWethLp,
        owner,
        3600, // 1 hours
    );
}

const _deploymentName = [
    DEPLOYMENT_NAMES.TOB_TAP_OPTION_ORACLE,
    DEPLOYMENT_NAMES.ADB_TAP_OPTION_ORACLE,
] as const;
const buildTapOptionOracle = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: (typeof _deploymentName)[number],
    tapAddress: string,
    tapWethLpPair: string,
    owner: string,
    fetchTime: number,
): Promise<IDeployerVMAdd<TapOptionOracle__factory>> => {
    const chainID = hre.SDK.eChainId;
    if (
        chainID !== hre.SDK.config.EChainID.ARBITRUM &&
        chainID !== hre.SDK.config.EChainID.ARBITRUM_SEPOLIA
    ) {
        throw '[-] TAP Oracle only available on Arbitrum or Arbitrum Sepolia';
    }

    const args: Parameters<TapOptionOracle__factory['deploy']> = [
        'TAP/USD', // Name
        'TAP/USD', // Symbol
        18, // Decimals
        fetchTime,
        getTapOracleMultiDeployParams({
            hre,
            tapAddress,
            tapWethLpPair,
            owner,
        }),
    ];

    return {
        contract: await hre.ethers.getContractFactory('TapOptionOracle'),
        deploymentName,
        args,
    };
};
