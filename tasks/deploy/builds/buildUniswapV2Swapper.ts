import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { UniswapV2Swapper__factory } from '../../../typechain';
import { ARGS_CONFIG } from '../CONF';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';

export const buildUniswapV2Swapper = async (
    hre: HardhatRuntimeEnvironment,
    tag: string,
): Promise<IDeployerVMAdd<UniswapV2Swapper__factory>> => {
    const chainInfo = hre.SDK.utils.getChainBy(
        'chainId',
        await hre.getChainId(),
    );
    if (!chainInfo) {
        throw new Error('[-] Chain not found');
    }
    const chainID = chainInfo.chainId;
    console.log(`chainID ${chainID}`);

    console.log(`ARGS_CONFIG[chainID] ${JSON.stringify(ARGS_CONFIG[chainID])}`);

    if (!ARGS_CONFIG[chainID]?.UNISWAPV2_ROUTER)
        throw new Error('[-] UniswapV2 Router not found');
    if (!ARGS_CONFIG[chainID]?.UNISWAPV2_FACTORY)
        throw new Error('[-] UniswapV2 Factory not found');

    let yb = hre.SDK.db
        .loadGlobalDeployment(
            tag,
            TAPIOCA_PROJECTS_NAME.YieldBox,
            chainInfo.chainId,
        )
        .find((e) => e.name == 'YieldBox');

    if (!yb) {
        yb = hre.SDK.db
            .loadLocalDeployment(tag, chainInfo.chainId)
            .find((e) => e.name == 'YieldBox');
    }
    if (!yb) throw new Error('[-] YieldBox not found');

    const deployer = (await hre.ethers.getSigners())[0];
    const args: Parameters<UniswapV2Swapper__factory['deploy']> = [
        ARGS_CONFIG[chainID]?.UNISWAPV2_ROUTER,
        ARGS_CONFIG[chainID]?.UNISWAPV2_FACTORY,
        yb.address,
        deployer.address,
    ];

    return {
        contract: await hre.ethers.getContractFactory('UniswapV2Swapper'),
        deploymentName: 'UniswapV2Swapper',
        args,
    };
};
