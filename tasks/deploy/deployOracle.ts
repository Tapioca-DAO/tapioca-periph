import { HardhatRuntimeEnvironment } from 'hardhat/types';

import { loadVM } from '../utils';
import inquirer from 'inquirer';
import { buildGLPOracle } from './builds/buildGLPOracle';
import { buildTapOracle } from './builds/buildTapOracle';
import { buildDaiOracle } from './builds/buildDaiOracle';
import { buildGMXOracle } from './builds/buildGMXOracle';

// hh deployOracles --network goerli
export const deployOracle__task = async (
    {},
    hre: HardhatRuntimeEnvironment,
) => {
    // Settings
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

    const deployType = [
        'GLPOracle',
        'TapOracle',
        'DaiOracle',
        'GMXOracle',
        // '[-] Deprecated / ARBTriCryptoOracle',
        // '[-] Deprecated / SGOracle',
    ] as const;

    const { buildToDeploy }: { buildToDeploy: (typeof deployType)[number] } =
        await inquirer.prompt({
            message: '[+] Build to deploy: ',
            name: 'buildToDeploy',
            type: 'list',
            choices: deployType,
        });

    const VM = await loadVM(hre, tag);

    // Build contracts
    if (buildToDeploy === 'GLPOracle') {
        VM.add(await buildGLPOracle(hre));
    }
    if (buildToDeploy === 'TapOracle') {
        VM.add(await buildTapOracle(hre));
    }
    if (buildToDeploy === 'DaiOracle') {
        VM.add(await buildDaiOracle(hre));
    }
    if (buildToDeploy === 'GMXOracle') {
        VM.add(await buildGMXOracle(hre));
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
