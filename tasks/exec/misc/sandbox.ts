import { TTapiocaDeployTaskArgs } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

export const sandbox__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    const { tag } = _taskArgs;
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });
    const tapiocaMulticallAddr = await VM.getMulticall();
    const signer = (await hre.ethers.getSigners())[0];
};
