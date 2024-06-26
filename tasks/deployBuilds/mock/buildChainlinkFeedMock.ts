import { ChainlinkFeedMock__factory } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const buildChainlinkFeedMock = async (
    hre: HardhatRuntimeEnvironment,
    params: {
        deploymentName: string;
        args: Parameters<ChainlinkFeedMock__factory['deploy']>;
    },
): Promise<IDeployerVMAdd<ChainlinkFeedMock__factory>> => {
    return {
        contract: await hre.ethers.getContractFactory('ChainlinkFeedMock'),
        deploymentName: params.deploymentName,
        args: params.args,
        meta: {
            decimals: params.args[0],
            rate: params.args[1],
        },
    };
};
