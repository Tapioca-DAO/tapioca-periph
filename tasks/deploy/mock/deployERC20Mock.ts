import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildERC20Mock } from 'tasks/deployBuilds/mock/buildERC20Mock';

export const deployERC20Mock__task = async (
    taskArgs: TTapiocaDeployTaskArgs & {
        name: string;
        decimals: number;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask<{ name: string }>(
        taskArgs,
        { hre },
        async ({ VM, tapiocaMulticallAddr }) => {
            VM.add(
                await buildERC20Mock(hre, {
                    deploymentName: taskArgs.name,
                    args: [
                        taskArgs.name,
                        taskArgs.name,
                        (1e18).toString(),
                        18,
                        tapiocaMulticallAddr,
                    ],
                }),
            );
        },
        async ({ VM }) => {
            const addr = VM.list().find(
                (e) => e.name === taskArgs.name,
            )!.address;
            console.log(`[+] ERC20Mock ${taskArgs.name} deployed at: ${addr}`);
        },
    );
};
