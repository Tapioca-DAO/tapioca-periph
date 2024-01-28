import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadVM } from '../utils';
import inquirer from 'inquirer';
import { buildStargateLbpHelper } from './builds/buildStargateLbpHelper';

export const deployStargateLbpHelper__task = async (
    taskArgs: { router: string, lbp: string, vault: string },
    hre: HardhatRuntimeEnvironment,
) => {

    const tag = await hre.SDK.hardhatUtils.askForTag(hre, 'local');
    const signer = (await hre.ethers.getSigners())[0];
    const chainInfo = hre.SDK.utils.getChainBy(
        'chainId',
        await hre.getChainId(),
    );
    console.log(
        '[+] Deploying on',
        chainInfo?.name,
        'with tag',
        tag,
        'and signer',
        signer.address,
    );

    const VM = await loadVM(hre, tag);
    
    VM.add(await buildStargateLbpHelper(hre, taskArgs.router, taskArgs.lbp, taskArgs.vault));

    // Add and execute
    await VM.execute(3);
    VM.save();
    await VM.verify();

    console.log('[+] Stack deployed! 🎉');

}