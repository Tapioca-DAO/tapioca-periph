import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { GLPOracle__factory } from '../../../typechain';
import { nonNullValues } from '../../utils';
import { ARGS_CONFIG } from '../config';

export const buildGLPOracle = async (
    hre: HardhatRuntimeEnvironment,
): Promise<IDeployerVMAdd<GLPOracle__factory>> => {
    console.log('[+] buildGLPOracle');

    const chainID = await hre.getChainId();
    if (chainID !== hre.SDK.config.EChainID.ARBITRUM) {
        throw '[-] GLP Oracle only available on Arbitrum';
    }
    const deployer = (await hre.ethers.getSigners())[0];

    const args: Parameters<GLPOracle__factory['deploy']> = [
        ARGS_CONFIG[chainID].GLP_ORACLE.GLP_MANAGER,
        ARGS_CONFIG[chainID].MISC.CL_SEQUENCER,
        deployer.address, // Owner
    ];

    // Displaying args for sanity check
    let i = 0;
    console.log('[+] With args:');
    console.log(`\t[${i}]GLP Manager:`, args[i++]);
    console.log(`\t[${i}]CL Sequencer:`, args[i++]);
    console.log(`\t[${i}]Owner:`, args[i++]);

    // Check for null values
    nonNullValues(args);

    return {
        contract: await hre.ethers.getContractFactory('GLPOracle'),
        deploymentName: 'GLPOracle',
        args,
    };
};
