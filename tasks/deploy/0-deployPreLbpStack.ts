import { HardhatRuntimeEnvironment } from 'hardhat/types';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildPauserManager } from 'tasks/deployBuilds/buildPauserManager';
import { buildMagnetar } from 'tasks/deployBuilds/magnetar/buildMagnetar';
import { buildMagnetarCollateralModule } from 'tasks/deployBuilds/magnetar/buildMagnetarCollateralModule';
import { buildMagnetarHelper } from 'tasks/deployBuilds/magnetar/buildMagnetarHelper';
import { buildMagnetarMintModule } from 'tasks/deployBuilds/magnetar/buildMagnetarMintModule';
import { buildMagnetarOptionModule } from 'tasks/deployBuilds/magnetar/buildMagnetarOptionModule';
import { buildYieldboxModule } from 'tasks/deployBuilds/magnetar/buildYieldboxModule';
import { buildTOEHelper } from 'tasks/deployBuilds/toe/buildTOEHelper';
import { buildZeroXSwapper } from 'tasks/deployBuilds/zeroXSwapper/buildZeroXSwapper';
import { buildZeroXSwapperMock } from 'tasks/deployBuilds/zeroXSwapper/buildZeroXSwapperMock';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from './DEPLOY_CONFIG';
import { loadLocalContract } from 'tapioca-sdk';

/**
 * @notice First thing to deploy
 *
 * Deploys:
 * - Pauser
 * - ToeHelper
 * - MagnetarCollateralModule
 * - MagnetarMintModule
 * - MagnetarOptionModule
 * - MagnetarYieldBoxModule
 * - Magnetar
 * - MagnetarHelper
 * - ZeroXSwapper
 *
 */
export const deployPreLbpStack__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre },
        tapiocaDeployTask,
    );
};

async function tapiocaDeployTask(params: TTapiocaDeployerVmPass<object>) {
    const {
        hre,
        VM,
        tapiocaMulticallAddr,
        chainInfo,
        taskArgs,
        isTestnet,
        isHostChain,
    } = params;
    const { tag } = taskArgs;
    const owner = tapiocaMulticallAddr;

    const { pearlmit, cluster } = loadContract__deployPreLbpStack(hre, tag);

    VM.add(await buildTOEHelper(hre, DEPLOYMENT_NAMES.TOE_HELPER, []))
        .add(
            await buildPauserManager(hre, DEPLOYMENT_NAMES.PAUSER, [
                cluster.address, // Cluster
                owner,
            ]),
        )
        .add(
            await buildMagnetarCollateralModule(
                hre,
                DEPLOYMENT_NAMES.MAGNETAR_COLLATERAL_MODULE,
                [
                    pearlmit.address, // Pearlmit
                    hre.ethers.constants.AddressZero, // ToeHelper
                ],
            ),
        )
        .add(
            await buildMagnetarMintModule(
                hre,
                DEPLOYMENT_NAMES.MAGNETAR_MINT_MODULE,
                [
                    pearlmit.address, // Pearlmit
                    hre.ethers.constants.AddressZero, // ToeHelper
                ],
            ),
        )
        .add(
            await buildMagnetarOptionModule(
                hre,
                DEPLOYMENT_NAMES.MAGNETAR_OPTION_MODULE,
                [
                    pearlmit.address, // Pearlmit
                    hre.ethers.constants.AddressZero, // ToeHelper
                ],
            ),
        )
        .add(
            await buildYieldboxModule(
                hre,
                DEPLOYMENT_NAMES.MAGNETAR_YIELDBOX_MODULE,
                [
                    pearlmit.address, // Pearlmit
                    hre.ethers.constants.AddressZero, // ToeHelper
                ],
            ),
        )
        .add(await buildMagnetarHelper(hre, DEPLOYMENT_NAMES.MAGNETAR_HELPER))
        .add(await getMagnetar(hre, tapiocaMulticallAddr, tag));

    if (isTestnet) {
        VM.add(
            await buildZeroXSwapperMock(hre, [
                cluster.address, // Cluster
                owner,
            ]),
        );
    } else {
        VM.add(
            await buildZeroXSwapper(hre, [
                DEPLOY_CONFIG.MISC[chainInfo.chainId]!.ZERO_X_PROXY!, // ZeroXProxy
                cluster.address, // Cluster
                owner,
            ]),
        );
    }
}

async function getMagnetar(
    hre: HardhatRuntimeEnvironment,
    owner: string,
    tag: string,
) {
    const { pearlmit, cluster } = loadContract__deployPreLbpStack(hre, tag);
    return await buildMagnetar(
        hre,
        DEPLOYMENT_NAMES.MAGNETAR,
        [
            cluster.address, // Cluster
            owner, // Owner
            '', // CollateralModule
            '', // MintModule
            '', // optionModule
            '', // YieldBoxModule
            pearlmit.address, // Pearlmit
            '', // ToeHelper
            '', // MagnetarHelper
        ],
        [
            {
                argPosition: 2,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_COLLATERAL_MODULE,
            },
            {
                argPosition: 3,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_MINT_MODULE,
            },
            {
                argPosition: 4,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_OPTION_MODULE,
            },
            {
                argPosition: 5,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_YIELDBOX_MODULE,
            },
            {
                argPosition: 7,
                deploymentName: DEPLOYMENT_NAMES.TOE_HELPER,
            },
            {
                argPosition: 8,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_HELPER,
            },
        ],
    );
}

async function getZeroXSwapper(data: {
    hre: HardhatRuntimeEnvironment;
    tag: string;
    owner: string;
    isTestnet: boolean;
}) {
    const { hre, tag, owner, isTestnet } = data;
}

function loadContract__deployPreLbpStack(
    hre: HardhatRuntimeEnvironment,
    tag: string,
) {
    const pearlmit = loadLocalContract(
        hre,
        hre.SDK.chainInfo.chainId,
        DEPLOYMENT_NAMES.PEARLMIT,
        tag,
    );
    const cluster = loadLocalContract(
        hre,
        hre.SDK.chainInfo.chainId,
        DEPLOYMENT_NAMES.CLUSTER,
        tag,
    );
    const yieldbox = loadLocalContract(
        hre,
        hre.SDK.chainInfo.chainId,
        DEPLOYMENT_NAMES.YIELDBOX,
        tag,
    );

    return { pearlmit, cluster, yieldbox };
}
