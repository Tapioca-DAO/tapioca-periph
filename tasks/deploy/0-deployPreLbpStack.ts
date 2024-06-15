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
import { DEPLOYMENT_NAMES } from './DEPLOY_CONFIG';

/**
 * @notice First thing to deploy
 *
 * Deploys:
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
        {
            hre,
        },
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

    VM.add(await buildTOEHelper(hre, DEPLOYMENT_NAMES.TOE_HELPER, []))
        .add(
            await buildPauserManager(
                hre,
                DEPLOYMENT_NAMES.PAUSER,
                [
                    '', // Cluster
                    owner,
                ],
                [
                    {
                        argPosition: 0,
                        deploymentName: DEPLOYMENT_NAMES.CLUSTER,
                    },
                ],
            ),
        )
        .add(
            await buildMagnetarCollateralModule(
                hre,
                DEPLOYMENT_NAMES.MAGNETAR_COLLATERAL_MODULE,
                [
                    hre.ethers.constants.AddressZero, // Pearlmit
                    hre.ethers.constants.AddressZero, // ToeHelper
                ],
            ),
        )
        .add(
            await buildMagnetarMintModule(
                hre,
                DEPLOYMENT_NAMES.MAGNETAR_MINT_MODULE,
                [
                    hre.ethers.constants.AddressZero, // Pearlmit
                    hre.ethers.constants.AddressZero, // ToeHelper
                ],
            ),
        )
        .add(
            await buildMagnetarOptionModule(
                hre,
                DEPLOYMENT_NAMES.MAGNETAR_OPTION_MODULE,
                [
                    hre.ethers.constants.AddressZero, // Pearlmit
                    hre.ethers.constants.AddressZero, // ToeHelper
                ],
            ),
        )
        .add(
            await buildYieldboxModule(
                hre,
                DEPLOYMENT_NAMES.MAGNETAR_YIELDBOX_MODULE,
                [
                    hre.ethers.constants.AddressZero, // Pearlmit
                    hre.ethers.constants.AddressZero, // ToeHelper
                ],
            ),
        )
        .add(await buildMagnetarHelper(hre, DEPLOYMENT_NAMES.MAGNETAR_HELPER))
        .add(await getMagnetar(hre, tapiocaMulticallAddr));

    if (isTestnet) {
        VM.add(
            await buildZeroXSwapperMock(
                hre,
                [
                    '', // Cluster
                    owner,
                ],
                [
                    {
                        argPosition: 0,
                        deploymentName: DEPLOYMENT_NAMES.CLUSTER,
                    },
                ],
            ),
        );
    } else {
        VM.add(await buildZeroXSwapper(hre, tag, owner));
    }
}

async function getMagnetar(hre: HardhatRuntimeEnvironment, owner: string) {
    return await buildMagnetar(
        hre,
        DEPLOYMENT_NAMES.MAGNETAR,
        [
            '', // Cluster
            owner, // Owner
            '', // CollateralModule
            '', // MintModule
            '', // optionModule
            '', // YieldBoxModule
            '', // Pearlmit
            '', // ToeHelper
            '', // MagnetarHelper
        ],
        [
            {
                argPosition: 0,
                deploymentName: DEPLOYMENT_NAMES.CLUSTER,
            },
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
                argPosition: 6,
                deploymentName: DEPLOYMENT_NAMES.PEARLMIT,
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
