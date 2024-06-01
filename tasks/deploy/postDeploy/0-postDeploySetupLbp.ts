import { WeightedPoolEncoder } from '@balancer-labs/balancer-js';
import { checkExists } from 'tapioca-sdk';
import { TTapiocaDeployerVmPass } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import {
    DEPLOY_LBP_CONFIG,
    deployLbp__compareAddresses,
    deployLbp__getDeployments,
} from '../1-deployLbp';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from '../DEPLOY_CONFIG';
import { TapiocaMulticall } from '@typechain/index';

export async function postDeploySetupLbp(
    params: TTapiocaDeployerVmPass<object>,
) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, chainInfo, isTestnet } =
        params;
    const { tag } = taskArgs;
    const owner = tapiocaMulticallAddr;

    const { lTap } = deployLbp__getDeployments({ hre, tag });

    const [tokenA_Data, tokenB_Data] = [
        {
            token: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.USDC!,
            startBalance: DEPLOY_LBP_CONFIG.START_BALANCES[0],
            endWeight: DEPLOY_LBP_CONFIG.END_WEIGHTS[0],
        },
        {
            token: lTap.address,
            startBalance: DEPLOY_LBP_CONFIG.START_BALANCES[1],
            endWeight: DEPLOY_LBP_CONFIG.END_WEIGHTS[1],
        },
    ].sort((a, b) => deployLbp__compareAddresses(a.token, b.token));

    const startBalances = [tokenA_Data.startBalance, tokenB_Data.startBalance];
    const endWeights = [tokenA_Data.endWeight, tokenB_Data.endWeight];

    const vault = await hre.ethers.getContractAt(
        'Vault',
        checkExists(
            hre,
            VM.list().find((dep) => dep.name === DEPLOYMENT_NAMES.LBP_VAULT),
            DEPLOYMENT_NAMES.LBP_VAULT,
            'This',
        ).address,
    );
    const lbp = await hre.ethers.getContractAt(
        'LiquidityBootstrappingPool',
        checkExists(
            hre,
            VM.list().find((dep) => dep.name === DEPLOYMENT_NAMES.TAP_USDC_LBP),
            DEPLOYMENT_NAMES.TAP_USDC_LBP,
            'This',
        ).address,
    );

    const tokenA = await hre.ethers.getContractAt(
        '@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20',
        tokenA_Data.token,
    );
    const tokenB = await hre.ethers.getContractAt(
        '@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20',
        tokenB_Data.token,
    );
    console.log('[+] Initializing LBP');

    const calls: TapiocaMulticall.CallStruct[] = [];
    console.log('\t[+] Add Approving token A');
    calls.push({
        target: tokenA.address,
        callData: tokenA.interface.encodeFunctionData('approve', [
            vault.address,
            tokenA_Data.startBalance,
        ]),
        allowFailure: false,
    });
    console.log('\t[+] Add Approving token B');
    calls.push({
        target: tokenB.address,
        callData: tokenB.interface.encodeFunctionData('approve', [
            vault.address,
            tokenB_Data.startBalance,
        ]),
        allowFailure: false,
    });
    console.log('\t[+] Add joining pool on vault');
    console.log([tokenA.address, tokenB.address]);
    calls.push({
        target: vault.address,
        callData: vault.interface.encodeFunctionData('joinPool', [
            await lbp.getPoolId(),
            owner,
            owner,
            {
                assets: [tokenA.address, tokenB.address],
                maxAmountsIn: startBalances,
                fromInternalBalance: false,
                userData: WeightedPoolEncoder.joinInit(startBalances),
            },
        ]),
        allowFailure: false,
    });
    console.log('\t[+] Add set swap enabled on LBP');
    calls.push({
        target: lbp.address,
        callData: lbp.interface.encodeFunctionData('setSwapEnabled', [true]),
        allowFailure: false,
    });

    const now = Math.floor(Date.now() / 1000);
    const endTime = now + DEPLOY_LBP_CONFIG.LBP_DURATION;
    console.log('\t[+] Add update weights gradually');
    calls.push({
        target: lbp.address,
        callData: lbp.interface.encodeFunctionData('updateWeightsGradually', [
            now,
            endTime,
            endWeights,
        ]),
        allowFailure: false,
    });

    await VM.executeMulticall(calls);
}
