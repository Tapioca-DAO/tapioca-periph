import { IDeployerVMAdd } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildCluster } from 'tasks/deployBuilds/cluster/buildCluster';
import { buildMagnetar } from 'tasks/deployBuilds/magnetar/buildMagnetar';
import { buildMagnetarAssetModule } from 'tasks/deployBuilds/magnetar/buildMagnetarAssetModule';
import { buildMagnetarCollateralModule } from 'tasks/deployBuilds/magnetar/buildMagnetarCollateralModule';
import { buildMagnetarMintModule } from 'tasks/deployBuilds/magnetar/buildMagnetarMintModule';
import { buildMagnetarOptionModule } from 'tasks/deployBuilds/magnetar/buildMagnetarOptionModule';
import { buildYieldboxModule } from 'tasks/deployBuilds/magnetar/buildYieldboxModule';
import { buildPearlmit } from 'tasks/deployBuilds/pearlmit/buildPearlmit';
import { buildTOEHelper } from 'tasks/deployBuilds/toe/buildTOEHelper';
import { buildZeroXSwapper } from 'tasks/deployBuilds/zeroXSwapper/buildZeroXSwapper';
import { buildZeroXSwapperMock } from 'tasks/deployBuilds/zeroXSwapper/buildZeroXSwapperMock';
import { DEPLOYMENT_NAMES } from './DEPLOY_CONFIG';

export const deployPreLbpStack__task = async (
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
            VM.add(
                await buildPearlmit(hre, DEPLOYMENT_NAMES.PEARLMIT, [
                    'Pearlmit',
                    '1',
                ]),
            )
                .add(
                    await buildCluster(hre, DEPLOYMENT_NAMES.CLUSTER, [
                        chainInfo.lzChainId,
                        tapiocaMulticallAddr,
                    ]),
                )
                .add(await buildTOEHelper(hre, DEPLOYMENT_NAMES.TOE_HELPER, []))
                .add(
                    await buildMagnetarAssetModule(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_ASSET_MODULE,
                        [
                            hre.ethers.constants.AddressZero, // Pearlmit
                            hre.ethers.constants.AddressZero, // ToeHelper
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
                .add(await getMagnetar(hre, tapiocaMulticallAddr))
                .add(
                    (await getZeroXSwapper({
                        hre,
                        tag: taskArgs.tag,
                        isTestnet,
                        owner: tapiocaMulticallAddr,
                    })) as IDeployerVMAdd<any>,
                );
        },
    );
};

async function getMagnetar(hre: HardhatRuntimeEnvironment, owner: string) {
    return await buildMagnetar(
        hre,
        DEPLOYMENT_NAMES.MAGNETAR,
        [
            hre.ethers.constants.AddressZero, // Cluster
            owner, // Owner
            hre.ethers.constants.AddressZero, // AssetModule
            hre.ethers.constants.AddressZero, // CollateralModule
            hre.ethers.constants.AddressZero, // MintModule
            hre.ethers.constants.AddressZero, // optionModule
            hre.ethers.constants.AddressZero, // YieldBoxModule
            hre.ethers.constants.AddressZero, // Pearlmit
            hre.ethers.constants.AddressZero, // ToeHelper
        ],
        [
            {
                argPosition: 0,
                deploymentName: DEPLOYMENT_NAMES.CLUSTER,
            },
            {
                argPosition: 2,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_ASSET_MODULE,
            },
            {
                argPosition: 3,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_COLLATERAL_MODULE,
            },
            {
                argPosition: 4,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_MINT_MODULE,
            },
            {
                argPosition: 5,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_OPTION_MODULE,
            },
            {
                argPosition: 6,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_YIELDBOX_MODULE,
            },
            {
                argPosition: 7,
                deploymentName: DEPLOYMENT_NAMES.PEARLMIT,
            },
            {
                argPosition: 8,
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
