import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { UniswapV3Swapper__factory } from '../../../typechain';
import { ARGS_CONFIG } from '../config';

export const buildUniswapV3Swapper = async (
    hre: HardhatRuntimeEnvironment,
    tag: string,
): Promise<IDeployerVMAdd<UniswapV3Swapper__factory>> => {
    const chainInfo = hre.SDK.utils.getChainBy(
        'chainId',
        await hre.getChainId(),
    );
    if (!chainInfo) {
        throw new Error('[-] Chain not found');
    }
    const chainID = chainInfo.chainId;

    if (!ARGS_CONFIG[chainID]?.UNISWAPV3_ROUTER)
        throw new Error('[-] UniswapV3 Router not found');
    if (!ARGS_CONFIG[chainID]?.UNISWAPV3_FACTORY)
        throw new Error('[-] UniswapV3 Factory not found');

    let yb = hre.SDK.db
        .loadGlobalDeployment(tag, 'YieldBox', chainInfo.chainId)
        .find((e) => e.name == 'YieldBox');

    if (!yb) {
        yb = hre.SDK.db
            .loadLocalDeployment(tag, chainInfo.chainId)
            .find((e) => e.name == 'YieldBox');
    }
    if (!yb) throw new Error('[-] YieldBox not found');

    const deployer = (await hre.ethers.getSigners())[0];
    const args: Parameters<UniswapV3Swapper__factory['deploy']> = [
        yb.address,
        ARGS_CONFIG[chainID]?.UNISWAPV3_ROUTER,
        ARGS_CONFIG[chainID]?.UNISWAPV3_FACTORY,
        deployer.address,
    ];

    return {
        contract: await hre.ethers.getContractFactory('UniswapV3Swapper'),
        deploymentName: 'UniswapV3Swapper',
        args,
    };
};
