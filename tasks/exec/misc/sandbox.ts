import { TTapiocaDeployTaskArgs } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const sandbox__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    const { tag } = _taskArgs;
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });
    const tapiocaMulticallAddr = await VM.getMulticall();
    const signer = (await hre.ethers.getSigners())[0];

    const mock = await hre.ethers.getContractAt(
        'ERC20Mock',
        '0x2eae4fbc552fe35c1d3df2b546032409bb0e431e',
    );

    await VM.executeMulticall([
        {
            allowFailure: false,
            callData: mock.interface.encodeFunctionData('transferOwnership', [
                '0x533385bc149b1aaa8cb958a592e96e4a0a81ce56',
            ]),
            target: mock.address,
        },
    ]);
};
