import { LiquidityBootstrappingPool__factory } from '@typechain/index';
import { BigNumberish } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

const compareAddresses = function (tokenA: string, tokenB: string): number {
    return tokenA.toLowerCase() > tokenB.toLowerCase() ? 1 : -1;
};
const sortTokens = (tokens: string[]): string[] => {
    return tokens.sort(compareAddresses);
};

export const buildLiquidityBootstrappingPool = async (
    hre: HardhatRuntimeEnvironment,
    deploymentName: string,
    args: {
        vault: string;
        name: string;
        symbol: string;
        tokens: string[];
        normalizedWeights: BigNumberish[];
        swapFeePercentage: BigNumberish;
        pauseWindowDuration: BigNumberish;
        bufferPeriodDuration: BigNumberish;
        owner: string;
        swapEnabledOnStart: boolean;
    },
): Promise<IDeployerVMAdd<LiquidityBootstrappingPool__factory>> => {
    const {
        vault,
        name,
        symbol,
        tokens,
        normalizedWeights,
        swapFeePercentage,
        pauseWindowDuration,
        bufferPeriodDuration,
        owner,
        swapEnabledOnStart,
    } = args;
    return {
        contract: new LiquidityBootstrappingPool__factory(
            hre.ethers.provider.getSigner(),
        ),
        deploymentName,
        args: [
            vault,
            name,
            symbol,
            sortTokens(tokens),
            normalizedWeights,
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner,
            swapEnabledOnStart,
        ],
        dependsOn: [
            {
                deploymentName: DEPLOYMENT_NAMES.LBP_VAULT,
                argPosition: 0,
            },
        ],
    };
};
