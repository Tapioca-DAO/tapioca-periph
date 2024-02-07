import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { EthGlpOracle__factory } from '../../../typechain';
import { nonNullValues } from '../../utils';
import { ARGS_CONFIG } from '../CONF';

export const __buildEthGlpOracleArgs = async (
    hre: HardhatRuntimeEnvironment,
    deployerAddr: string,
    wethUsdOracle: string,
    glpUsdOracle: string,
): Promise<Parameters<EthGlpOracle__factory['deploy']>> => {
    const chainID = hre.SDK.eChainId;
    if (chainID !== hre.SDK.config.EChainID.ARBITRUM) {
        throw '[-] EthGlp Oracle only available on Arbitrum';
    }

    const args: Parameters<EthGlpOracle__factory['deploy']> = [
        wethUsdOracle,
        glpUsdOracle,
        ARGS_CONFIG[chainID].MISC.CL_SEQUENCER,
        deployerAddr, // Owner
    ];
    // Check for null values
    nonNullValues(args);

    return args;
};

export const buildEthGlpPOracle = async (
    hre: HardhatRuntimeEnvironment,
    wethUsdOracle: string,
    glpUsdOracle: string,
): Promise<IDeployerVMAdd<EthGlpOracle__factory>> => {
    console.log('[+] buildEthGlpOracle');
    const deployer = (await hre.ethers.getSigners())[0];

    const args = await __buildEthGlpOracleArgs(
        hre,
        deployer.address,
        wethUsdOracle,
        glpUsdOracle,
    );

    // Displaying args for sanity check
    let i = 0;
    console.log('[+] With args:');
    console.log(`\t[${i}]WETH/USD Oracle:`, args[i++]);
    console.log(`\t[${i}]GLP/USD Oracle:`, args[i++]);
    console.log(`\t[${i}]CL Sequencer:`, args[i++]);
    console.log(`\t[${i}]Owner:`, args[i++]);

    return {
        contract: await hre.ethers.getContractFactory('EthGlpOracle'),
        deploymentName: 'EthGlpOracle',
        args,
    };
};
