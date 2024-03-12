import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { buildERC20Mock } from 'tasks/deployBuilds/mock/buildERC20Mock';
import { loadVM } from 'tasks/utils';

export const deployERC20Mock__task = async (
    taskArgs: {
        name: string;
        tag?: string;
        load?: boolean;
        verify?: boolean;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    // Settings
    const tag = taskArgs.tag ?? 'default';
    const VM = await loadVM(hre, tag);
    const chainInfo = hre.SDK.utils.getChainBy('chainId', hre.SDK.eChainId)!;

    const isTestnet = !!chainInfo.tags.find((tag) => tag === 'testnet');
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
            await buildERC20Mock(hre, {
                deploymentName: 'ERC20Mock',
                args: [
                    taskArgs.name,
                    taskArgs.name,
                    (1e18).toString(),
                    18,
                    tapiocaMulticall.address,
                ],
            }),
        );

        // Add and execute
        await VM.execute();
        await VM.save();
    }

    if (taskArgs.verify) {
        await VM.verify();
    }

    console.log('[+] Pre LBP Stack deployed! 🎉');
};
