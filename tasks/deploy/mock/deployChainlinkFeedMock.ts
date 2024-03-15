import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildChainlinkFeedMock } from 'tasks/deployBuilds/mock/buildChainlinkFeedMock';

export const deployChainlinkFeedMock__task = async (
    taskArgs: TTapiocaDeployTaskArgs & {
        name: string;
        rate: string;
        decimals: number;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask<{ name: string }>(
        taskArgs,
        { hre },
        async ({ VM }) => {
            VM.add(
                await buildChainlinkFeedMock(hre, {
                    deploymentName: taskArgs.name,
                    args: [taskArgs.decimals, taskArgs.rate],
                }),
            );
        },
        async ({ VM }) => {
            const addr = VM.list().find(
                (e) => e.name === taskArgs.name,
            )!.address;
            console.log(
                `[+] ChainlinkFeedMock ${taskArgs.name} address: ${addr}`,
            );
        },
    );
};
