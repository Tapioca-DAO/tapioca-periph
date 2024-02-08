import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadVM } from '../utils';
import inquirer from 'inquirer';
import { buildUniswapV2Swapper } from './builds/buildUniswapV2Swapper';
import { buildUniswapV3Swapper } from './builds/buildUniswapV3Swapper';

// hh deploySwappers --network goerli
export const deploySwappers__task = async (
    {},
    hre: HardhatRuntimeEnvironment,
) => {
    const tag = await hre.SDK.hardhatUtils.askForTag(hre, 'local');
    const signer = (await hre.ethers.getSigners())[0];
    const chainInfo = hre.SDK.utils.getChainBy('chainId', hre.SDK.eChainId);
    console.log(
        '[+] Deploying on',
        chainInfo?.name,
        'with tag',
        tag,
        'and signer',
        signer.address,
    );

    const deployType = ['UniswapV2Swapper', 'UniswapV3Swapper'] as const;
    const { buildToDeploy }: { buildToDeploy: (typeof deployType)[number] } =
        await inquirer.prompt({
            message: '[+] Build to deploy: ',
            name: 'buildToDeploy',
            type: 'list',
            choices: deployType,
        });

    const VM = await loadVM(hre, tag);
    // Build contracts
    if (buildToDeploy === 'UniswapV2Swapper') {
        VM.add(await buildUniswapV2Swapper(hre, tag));
    }
    if (buildToDeploy === 'UniswapV3Swapper') {
        VM.add(await buildUniswapV3Swapper(hre, tag));
    }

    const isLocal = hre.network.config.tags.includes('local');

    // Add and execute
    await VM.execute(isLocal ? 0 : 3);
    if (!isLocal) {
        VM.save();
        await VM.verify();
    }

    console.log('[+] Stack deployed! 🎉');
};
