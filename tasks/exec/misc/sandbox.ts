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
        '0x2EAe4fbc552fE35C1D3Df2B546032409bb0E431E',
    );

    await VM.executeMulticall([
        {
            allowFailure: false,
            callData: mock.interface.encodeFunctionData('setWhitelist', [
                '0x3D61dbA293184b8D6a4a365DeCf09cA77D0CBDB3',
                true,
            ]),
            target: mock.address,
        },
    ]);
};
