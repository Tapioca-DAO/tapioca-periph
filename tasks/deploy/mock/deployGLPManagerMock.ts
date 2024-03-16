import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildGLPManagerMock } from 'tasks/deployBuilds/mock/buildGLPManagerMock';

export const deployGLPManagerMock__task = async (
    taskArgs: TTapiocaDeployTaskArgs & {
        name: string;
        glpPrice: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask<{ name: string }>(
        taskArgs,
        { hre },
        async ({ VM }) => {
            VM.add(
                await buildGLPManagerMock(hre, {
                    deploymentName: taskArgs.name,
                    args: [taskArgs.glpPrice],
                }),
            );
        },
        async ({ VM }) => {
            const addr = VM.list().find(
                (e) => e.name === taskArgs.name,
            )!.address;
            console.log(`[+] GLPManagerMock ${taskArgs.name} address: ${addr}`);
        },
    );
};
