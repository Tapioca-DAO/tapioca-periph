import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { buildMagnetar } from 'tasks/deployBuilds/magnetar/buildMagnetar';
import { buildPearlmit } from 'tasks/deployBuilds/pearlmit/buildPearlmit';
import { loadVM } from 'tasks/utils';
import { DEPLOYMENT_NAMES } from './DEPLOY_CONFIG';
import { buildMagnetarAssetModule } from 'tasks/deployBuilds/magnetar/buildMagnetarAssetModule';
import { buildMagnetarAssetXChainModule } from 'tasks/deployBuilds/magnetar/buildMagnetarAssetXChainModule';
import { buildMagnetarCollateralModule } from 'tasks/deployBuilds/magnetar/buildMagnetarCollateralModule';
import { buildMagnetarMintModule } from 'tasks/deployBuilds/magnetar/buildMagnetarMintModule';
import { buildMagnetarMintXChainModule } from 'tasks/deployBuilds/magnetar/buildMagnetarMintXChainModule';
import { buildMagnetarOptionModule } from 'tasks/deployBuilds/magnetar/buildMagnetarOptionModule';
import { buildYieldboxModule } from 'tasks/deployBuilds/magnetar/buildYieldboxModule';
import { buildCluster } from 'tasks/deployBuilds/cluster/buildCluster';

export const deployPreLbpStack__task = async (
    taskArgs: { tag?: string; load?: boolean; verify: boolean },
    hre: HardhatRuntimeEnvironment,
) => {
    // Settings
    const tag = taskArgs.tag ?? 'default';
    const VM = await loadVM(hre, tag);
    const chainInfo = hre.SDK.utils.getChainBy('chainId', hre.SDK.eChainId)!;

    const isTestnet = chainInfo.tags.find((tag) => tag === 'testnet');
    const tapiocaMulticall = await VM.getMulticall();

    // Build contracts
    if (taskArgs.load) {
        console.log(`[+] Loading contracts from ${tag} deployment... 📡`);
        console.log(
            `\t[+] ${hre.SDK.db
                .loadLocalDeployment(tag, hre.SDK.eChainId)
                ?.contracts.map((e) => e.name)
                .reduce((a, b) => `${a}, ${b}`)}`,
        );

        VM.load(
            hre.SDK.db.loadLocalDeployment(tag, hre.SDK.eChainId)?.contracts ??
                [],
        );
    } else {
        VM.add(
            await buildPearlmit(hre, DEPLOYMENT_NAMES.PEARLMIT, [
                'Pearlmit',
                '1',
            ]),
        )
            .add(
                await buildCluster(hre, DEPLOYMENT_NAMES.CLUSTER, [
                    chainInfo.lzChainId,
                    tapiocaMulticall.address,
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
                    [],
                ),
            )
            .add(
                await buildMagnetarMintXChainModule(
                    hre,
                    DEPLOYMENT_NAMES.MAGNETAR_MINT_X_CHAIN_MODULE,
                    [],
                ),
            )
            .add(
                await buildMagnetarOptionModule(
                    hre,
                    DEPLOYMENT_NAMES.MAGNETAR_OPTION_MODULE,
                    [],
                ),
            )
            .add(
                await buildYieldboxModule(
                    hre,
                    DEPLOYMENT_NAMES.MAGNETAR_YIELDBOX_MODULE,
                    [],
                ),
            )
            .add(await getMagnetar(hre, tapiocaMulticall.address));

        // Add and execute
        await VM.execute();
        await VM.save();
    }

    if (taskArgs.verify) {
        await VM.verify();
    }

    console.log('[+] Pre LBP Stack deployed! 🎉');
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
