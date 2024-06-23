import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildMagnetar } from 'tasks/deployBuilds/magnetar/buildMagnetar';
import { buildMagnetarCollateralModule } from 'tasks/deployBuilds/magnetar/buildMagnetarCollateralModule';
import { buildMagnetarHelper } from 'tasks/deployBuilds/magnetar/buildMagnetarHelper';
import { buildMagnetarMintModule } from 'tasks/deployBuilds/magnetar/buildMagnetarMintModule';
import { buildMagnetarOptionModule } from 'tasks/deployBuilds/magnetar/buildMagnetarOptionModule';
import { buildYieldboxModule } from 'tasks/deployBuilds/magnetar/buildYieldboxModule';
import { buildZeroXSwapper } from 'tasks/deployBuilds/zeroXSwapper/buildZeroXSwapper';
import { buildZeroXSwapperMock } from 'tasks/deployBuilds/zeroXSwapper/buildZeroXSwapperMock';
import { DEPLOYMENT_NAMES } from './DEPLOY_CONFIG';

/**
 * Used for deploying Magnetar only
 */
export const deployMagnetarOnly__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre },
        async ({
            VM,
            tapiocaMulticallAddr,
            chainInfo,
            taskArgs,
            isTestnet,
        }) => {
            const { tag } = taskArgs;
            VM.add(
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
                .add(await getMagnetar(hre, tapiocaMulticallAddr, tag))
                .add(
                    await buildMagnetarHelper(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_HELPER,
                    ),
                );
        },
    );
};

async function getMagnetar(
    hre: HardhatRuntimeEnvironment,
    owner: string,
    tag: string,
) {
    return await buildMagnetar(
        hre,
        DEPLOYMENT_NAMES.MAGNETAR,
        [
            loadLocalContract(
                hre,
                hre.SDK.chainInfo.chainId,
                DEPLOYMENT_NAMES.CLUSTER,
                tag,
            ).address, // Cluster
            owner, // Owner
            hre.ethers.constants.AddressZero, // CollateralModule
            hre.ethers.constants.AddressZero, // MintModule
            hre.ethers.constants.AddressZero, // optionModule
            hre.ethers.constants.AddressZero, // YieldBoxModule
            loadLocalContract(
                hre,
                hre.SDK.chainInfo.chainId,
                DEPLOYMENT_NAMES.PEARLMIT,
                tag,
            ).address, // Pearlmit
            loadLocalContract(
                hre,
                hre.SDK.chainInfo.chainId,
                DEPLOYMENT_NAMES.TOE_HELPER,
                tag,
            ).address, // ToeHelper
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

    if (isTestnet) {
        return await buildZeroXSwapperMock(hre);
    } else {
        return await buildZeroXSwapper(hre, tag, owner);
    }
}
