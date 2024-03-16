import NonfungiblePositionManagerArtifact from '@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json';
import { encodeSqrtRatioX96 } from '@uniswap/v3-sdk';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { checkExists } from 'tapioca-sdk';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOY_CONFIG } from '../DEPLOY_CONFIG';
import { ERC20 } from '@typechain/@openzeppelin/contracts/token/ERC20';

export const deployUniV3pool__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        feeTier: number;
        token0: string;
        token1: string;
        ratio0: number;
        ratio1: number;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    const { tag } = _taskArgs;
    const { v3CoreFactory, positionManager } = await loadContract(hre, tag!);
    const feeTier = validateFeeTier(_taskArgs.feeTier);

    const [token0, token1, ratio0, ratio1] = sortTokens(
        _taskArgs.token0,
        _taskArgs.token1,
        _taskArgs.ratio0,
        _taskArgs.ratio1,
    );

    {
        const token0Contract = (await hre.ethers.getContractAt(
            '@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20',
            token0,
        )) as ERC20;
        const token1Contract = (await hre.ethers.getContractAt(
            '@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20',
            token1,
        )) as ERC20;
        const token0Name = await token0Contract.name();
        const token1Name = await token1Contract.name();
        console.log(
            `[+] Creating ${token0Name}/${token1Name} with - fee ${feeTier} - ratio ${ratio0}/${ratio1} ...`,
        );
    }

    await (
        await positionManager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            feeTier,
            encodeSqrtRatioX96(ratio0, ratio1).toString(),
            {
                gasLimit: 5_000_000,
            },
        )
    ).wait(3);

    const poolAddress = await v3CoreFactory.getPool(token0, token1, feeTier);
    console.log(`[+] Pool created at address: ${poolAddress}`);

    return poolAddress;
};

function validateFeeTier(feeTier: number) {
    if (![500, 3000, 10000].includes(feeTier)) {
        throw new Error(`Invalid fee tier: ${feeTier}`);
    }
    return feeTier;
}

function sortTokens(
    token0: string,
    token1: string,
    ratio0: number,
    ratio1: number,
) {
    return token0.toLowerCase() < token1.toLowerCase()
        ? ([token0, token1, ratio0, ratio1] as const)
        : ([token1, token0, ratio1, ratio0] as const);
}

async function loadContract(hre: HardhatRuntimeEnvironment, tag: string) {
    const positionManager = (
        await hre.ethers.getContractFactoryFromArtifact(
            NonfungiblePositionManagerArtifact,
        )
    ).attach(
        checkExists(
            hre,
            DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.NONFUNGIBLE_POSITION_MANAGER,
            'nonfungibleTokenPositionManager',
            'DEPLOY_CONFIG.MISC',
        ),
    );

    const v3CoreFactory = await hre.ethers.getContractAt(
        'IUniswapV3Factory',
        checkExists(
            hre,
            DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.V3_FACTORY,
            'v3CoreFactory',
            'DEPLOY_CONFIG.MISC',
        ),
    );

    return { v3CoreFactory, positionManager };
}
