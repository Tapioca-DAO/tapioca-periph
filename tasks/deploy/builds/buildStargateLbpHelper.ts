import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { StargateLbpHelper__factory } from '../../../typechain';

export const buildStargateLbpHelper = async (
    hre: HardhatRuntimeEnvironment,
    router: string,
    lbp: string,
    vault: string,
): Promise<IDeployerVMAdd<StargateLbpHelper__factory>> => {
    console.log('[+] Building StargateLbpHelper');

    const deployer = (await hre.ethers.getSigners())[0];

    const args: Parameters<StargateLbpHelper__factory['deploy']> = [
        router,
        lbp,
        vault,
        deployer.address,
    ];

    return {
        contract: await hre.ethers.getContractFactory('StargateLbpHelper'),
        deploymentName: 'StargateLbpHelper',
        args,
    };
};
