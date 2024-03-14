import * as TAP_TOKEN_DEPLOY_CONFIG from '@tap-token/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import NonfungiblePositionManagerArtifact from '@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json';
import { encodeSqrtRatioX96 } from '@uniswap/v3-sdk';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOY_CONFIG } from '../DEPLOY_CONFIG';
import { checkExists, loadGlobalContract } from 'tapioca-sdk';

export const deployUniV3EnvMock__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    const { tag } = _taskArgs;
    const { tapToken, usdo, v3CoreFactory, positionManager } =
        await loadContract(hre, tag!);
    const feeTier = 3000;

    console.log('[+] Creating pool...');
    await (
        await positionManager.createAndInitializePoolIfNecessary(
            usdo.address,
            tapToken.address,
            feeTier,
            encodeSqrtRatioX96(33, 1).toString(),
            {
                gasLimit: 5_000_000,
            },
        )
    ).wait(3);

    const poolAddress = await v3CoreFactory.getPool(
        tapToken.address,
        usdo.address,
        feeTier,
    );

    console.log(`[+] Pool created at address: ${poolAddress}`);
};

async function loadContract(hre: HardhatRuntimeEnvironment, tag: string) {
    const tapToken = loadGlobalContract(
        hre,
        TAPIOCA_PROJECTS_NAME.TapToken,
        hre.SDK.eChainId,
        TAP_TOKEN_DEPLOY_CONFIG.DEPLOYMENT_NAMES.TAP_TOKEN,
        tag,
    );

    const usdo = loadGlobalContract(
        hre,
        TAPIOCA_PROJECTS_NAME.TapiocaBar,
        hre.SDK.eChainId,
        'USDO', // TODO replace by BAR NAME CONFIG
        tag,
    );

    const positionManager = (
        await hre.ethers.getContractFactoryFromArtifact(
            NonfungiblePositionManagerArtifact,
        )
    ).attach(
        checkExists(
            hre,
            DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!
                .nonfungibleTokenPositionManager,
            'nonfungibleTokenPositionManager',
            'DEPLOY_CONFIG.MISC',
        ),
    );

    const v3CoreFactory = await hre.ethers.getContractAt(
        'IUniswapV3Factory',
        checkExists(
            hre,
            DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.v3CoreFactory,
            'v3CoreFactory',
            'DEPLOY_CONFIG.MISC',
        ),
    );

    return { tapToken, usdo, v3CoreFactory, positionManager };
}
