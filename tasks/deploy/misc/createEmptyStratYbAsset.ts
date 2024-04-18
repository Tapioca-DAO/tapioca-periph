import * as TAP_YIELDBOX from '@tap-yieldbox/config';
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadGlobalContract } from 'tapioca-sdk';
import { saveBuildLocally } from '@tapioca-sdk/api/db';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

export const createEmptyStratYbAsset__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        token: string;
        deploymentName: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    const { tag } = _taskArgs;
    const { token, deploymentName } = _taskArgs;

    console.log(`[+] Creating empty strat  YieldBox asset for ${token}...`);

    const yieldBox = await hre.ethers.getContractAt(
        'tapioca-periph/interfaces/yieldbox/IYieldBox.sol:IYieldBox',
        loadGlobalContract(
            hre,
            TAPIOCA_PROJECTS_NAME.YieldBox,
            hre.SDK.eChainId,
            TAP_YIELDBOX.DEPLOYMENT_NAMES.YieldBox,
            tag,
        ).address,
    );

    console.log('[+] Deploying ERC20WithoutStrategy');
    const tokenStrat = await (
        await hre.ethers.getContractFactory('ERC20WithoutStrategy')
    ).deploy(yieldBox.address, token);
    await tokenStrat.deployed();

    console.log(`[+] Registering asset ${token} with YieldBox...`);
    await (
        await yieldBox.registerAsset(1, token, tokenStrat.address, 0)
    ).wait(3);

    const tokenStratId = (await yieldBox.assetCount()).sub(1);

    console.log(
        `[+] Saving deployment of asset ${token} registered with YieldBox at ${
            tokenStrat.address
        }, with ID ${tokenStratId.toNumber()}, under ${deploymentName}`,
    );

    saveBuildLocally(
        {
            chainId: hre.SDK.eChainId,
            chainIdName: hre.SDK.chainInfo.name,
            contracts: [
                {
                    address: tokenStrat.address,
                    name: deploymentName,
                    meta: {
                        token,
                        ybAssetId: tokenStratId.toNumber(),
                    },
                },
            ],
            lastBlockHeight: await hre.ethers.provider.getBlockNumber(),
        },
        tag,
    );
};
