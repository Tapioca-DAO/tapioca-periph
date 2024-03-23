import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { buildMagnetar } from 'tasks/deployBuilds/magnetar/buildMagnetar';
import { buildPearlmit } from 'tasks/deployBuilds/pearlmit/buildPearlmit';
import { loadVM } from 'tasks/utils';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from './DEPLOY_CONFIG';
import { buildMagnetarAssetModule } from 'tasks/deployBuilds/magnetar/buildMagnetarAssetModule';
import { buildMagnetarAssetXChainModule } from 'tasks/deployBuilds/magnetar/buildMagnetarAssetXChainModule';
import { buildMagnetarCollateralModule } from 'tasks/deployBuilds/magnetar/buildMagnetarCollateralModule';
import { buildMagnetarMintModule } from 'tasks/deployBuilds/magnetar/buildMagnetarMintModule';
import { buildMagnetarMintXChainModule } from 'tasks/deployBuilds/magnetar/buildMagnetarMintXChainModule';
import { buildMagnetarOptionModule } from 'tasks/deployBuilds/magnetar/buildMagnetarOptionModule';
import { buildYieldboxModule } from 'tasks/deployBuilds/magnetar/buildYieldboxModule';
import { buildCluster } from 'tasks/deployBuilds/cluster/buildCluster';
import { buildZeroXSwapper } from 'tasks/deployBuilds/zeroXSwapper/buildZeroXSwapper';
import { buildZeroXSwapperMock } from 'tasks/deployBuilds/zeroXSwapper/buildZeroXSwapperMock';
import { IDeployerVMAdd } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildMagnetarBaseModuleExternal } from 'tasks/deployBuilds/magnetar/buildMagnetarBaseModuleExternal';

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
                    await buildMagnetarBaseModuleExternal(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_BASE_MODULE_EXTERNAL,
                        [],
                    ),
                )
                .add(
                    await buildCluster(hre, DEPLOYMENT_NAMES.CLUSTER, [
                        chainInfo.lzChainId,
                        tapiocaMulticallAddr,
                    ]),
                )
                .add(
                    await buildMagnetarAssetModule(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_ASSET_MODULE,
                        [],
                    ),
                )
                .add(
                    await buildMagnetarAssetXChainModule(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_ASSET_X_CHAIN_MODULE,
                        [],
                    ),
                )
                .add(
                    await buildMagnetarCollateralModule(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_COLLATERAL_MODULE,
                        [],
                    ),
                )
                .add(
                    await buildMagnetarMintModule(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_MINT_MODULE,
                        [
                            '0x', // MagnetarBaseModuleExternal
                        ],
                        [
                            {
                                argPosition: 0,
                                deploymentName:
                                    DEPLOYMENT_NAMES.MAGNETAR_BASE_MODULE_EXTERNAL,
                            },
                        ],
                    ),
                )
                .add(
                    await buildMagnetarMintXChainModule(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_MINT_X_CHAIN_MODULE,
                        [
                            '0x', // MagnetarBaseModuleExternal
                        ],
                        [
                            {
                                argPosition: 0,
                                deploymentName:
                                    DEPLOYMENT_NAMES.MAGNETAR_BASE_MODULE_EXTERNAL,
                            },
                        ],
                    ),
                )
                .add(
                    await buildMagnetarOptionModule(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_OPTION_MODULE,
                        [
                            '0x', // MagnetarBaseModuleExternal
                        ],
                        [
                            {
                                argPosition: 0,
                                deploymentName:
                                    DEPLOYMENT_NAMES.MAGNETAR_BASE_MODULE_EXTERNAL,
                            },
                        ],
                    ),
                )
                .add(
                    await buildYieldboxModule(
                        hre,
                        DEPLOYMENT_NAMES.MAGNETAR_YIELDBOX_MODULE,
                        [],
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
            hre.ethers.constants.AddressZero, // AssetXChainModule
            hre.ethers.constants.AddressZero, // CollateralModule
            hre.ethers.constants.AddressZero, // MintModule
            hre.ethers.constants.AddressZero, // MintXChainModule
            hre.ethers.constants.AddressZero, // optionModule
            hre.ethers.constants.AddressZero, // YieldBoxModule
            hre.ethers.constants.AddressZero, // Pearlmit
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
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_ASSET_X_CHAIN_MODULE,
            },
            {
                argPosition: 4,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_COLLATERAL_MODULE,
            },
            {
                argPosition: 5,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_MINT_MODULE,
            },
            {
                argPosition: 6,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_MINT_X_CHAIN_MODULE,
            },
            {
                argPosition: 7,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_OPTION_MODULE,
            },
            {
                argPosition: 8,
                deploymentName: DEPLOYMENT_NAMES.MAGNETAR_YIELDBOX_MODULE,
            },
            {
                argPosition: 9,
                deploymentName: DEPLOYMENT_NAMES.PEARLMIT,
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
