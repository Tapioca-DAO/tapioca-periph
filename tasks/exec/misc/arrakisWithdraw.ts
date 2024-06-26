import { TTapiocaDeployTaskArgs } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { TapiocaMulticall } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import { TTapiocaDeployerVmPass } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const arrakisWithdraw__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        vault: string;
        percentage: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre, staticSimulation: false },
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        async () => {},
        setup,
    );
};

async function setup(
    params: TTapiocaDeployerVmPass<{
        vault: string;
        percentage: string;
    }>,
) {
    const { hre, VM, isTestnet, isHostChain, tapiocaMulticallAddr } = params;
    const { tag, percentage, vault } = params.taskArgs;

    const calls: TapiocaMulticall.CallStruct[] = [];

    console.log(
        `[+] Withdrawing from Arrakis Vault ${Number(percentage) / 100}% ...`,
    );

    const arrakis = await hre.ethers.getContractAt(
        'IArrakisV2Vault',
        loadLocalContract(
            hre,
            hre.SDK.chainInfo.chainId,
            DEPLOYMENT_NAMES.ARRAKIS_TAP_WETH_VAULT,
            tag,
        ).address,
    );

    const balance = await arrakis.balanceOf(tapiocaMulticallAddr);
    console.log(`[+] Current balance: ${balance.toString()}`);

    const toWithdraw = balance.mul(percentage).div(10_000);
    console.log(
        `[+] Withdrawing ${hre.ethers.utils.formatEther(toWithdraw)} ...`,
    );

    calls.push({
        target: arrakis.address,
        callData: arrakis.interface.encodeFunctionData('burn', [
            toWithdraw,
            tapiocaMulticallAddr,
        ]),
        allowFailure: false,
    });

    await VM.executeMulticall(calls);
}
