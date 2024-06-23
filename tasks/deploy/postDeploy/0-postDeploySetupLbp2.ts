import { TapiocaMulticall } from '@typechain/index';
import { loadLocalContract } from 'tapioca-sdk';
import { TTapiocaDeployerVmPass } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from '../DEPLOY_CONFIG';

export async function postDeploySetupLbp2(
    params: TTapiocaDeployerVmPass<object>,
) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, chainInfo, isTestnet } =
        params;
    const { tag } = taskArgs;

    const lbp = await hre.ethers.getContractAt(
        'LiquidityBootstrappingPool',
        loadLocalContract(
            hre,
            hre.SDK.chainInfo.chainId,
            DEPLOYMENT_NAMES.TAP_USDC_LBP,
            tag,
        ).address,
    );

    const calls: TapiocaMulticall.CallStruct[] = [];
    console.log('\t[+] Add set swap enabled on LBP');
    calls.push({
        target: lbp.address,
        callData: lbp.interface.encodeFunctionData('setSwapEnabled', [true]),
        allowFailure: false,
    });

    await VM.executeMulticall(calls);
}
