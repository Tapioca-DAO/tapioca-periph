import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { checkExists } from 'tapioca-sdk';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const disableLbpSwaps__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre },
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        async () => {},
        postDeployTask,
    );
};

async function postDeployTask(params: TTapiocaDeployerVmPass<object>) {
    const { hre, VM, chainInfo, taskArgs, isTestnet } = params;
    const { tag, load } = taskArgs;

    if (!load) {
        throw new Error('[-] Task needs to load contracts with --load flag');
    }

    const lbpAddr = checkExists(
        hre,
        VM.list().find((e) => e.name === DEPLOYMENT_NAMES.TAP_USDC_LBP),
        DEPLOYMENT_NAMES.TAP_USDC_LBP,
        'periph',
    );

    const lbp = await hre.ethers.getContractAt(
        'LiquidityBootstrappingPool',
        lbpAddr.address,
    );

    if ((await lbp.getSwapEnabled()) === true) {
        console.log('[+] Disabling LBP swaps');
        await VM.executeMulticall([
            {
                allowFailure: false,
                callData: lbp.interface.encodeFunctionData('setSwapEnabled', [
                    false,
                ]),
                target: lbp.address,
            },
        ]);
    } else {
        console.log('[+] LBP swaps already disabled');
    }
}
