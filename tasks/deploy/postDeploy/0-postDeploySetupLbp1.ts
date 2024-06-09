import { WeightedPoolEncoder } from '@balancer-labs/balancer-js';
import { checkExists } from 'tapioca-sdk';
import { TTapiocaDeployerVmPass } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import {
    DEPLOY_LBP_CONFIG,
    deployLbp__compareAddresses,
    deployLbp__getDeployments,
} from '../1-1-deployLbp';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from '../DEPLOY_CONFIG';
import { TapiocaMulticall } from '@typechain/index';
import { ethers } from 'ethers';
import { fp } from 'tasks/deployBuilds/lbp/LBPNumbersUtils';

export async function postDeploySetupLbp1(
    params: TTapiocaDeployerVmPass<{
        ltapAmount: string;
        usdcAmount: string;
        startTimestamp: string;
    }>,
) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, chainInfo, isTestnet } =
        params;
    const { tag, ltapAmount, usdcAmount, startTimestamp } = taskArgs;
    const owner = tapiocaMulticallAddr;

    DEPLOY_LBP_CONFIG.START_BALANCES = [
        ethers.BigNumber.from(usdcAmount).mul(1e6), // 6 decimals
        fp(ltapAmount), // 18 decimals
    ];

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

    if (isTestnet) {
        console.log(
            '[+] Minting Mock USDC for LBP',
            hre.ethers.utils.formatUnits(
                DEPLOY_LBP_CONFIG.START_BALANCES[0],
                6,
            ),
        );

        const mockToken = await hre.ethers.getContractAt(
            'ERC20Mock',
            DEPLOY_CONFIG.MISC[chainInfo.chainId]!.USDC,
        );

        calls.push({
            target: mockToken.address,
            callData: mockToken.interface.encodeFunctionData('mintTo', [
                tapiocaMulticallAddr,
                DEPLOY_LBP_CONFIG.START_BALANCES[0],
            ]),
            allowFailure: false,
        });
    }

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

    const endTime = startTimestamp + DEPLOY_LBP_CONFIG.LBP_DURATION;
    console.log('\t[+] Add update weights gradually');
    calls.push({
        target: lbp.address,
        callData: lbp.interface.encodeFunctionData('updateWeightsGradually', [
            startTimestamp,
            endTime,
            endWeights,
        ]),
        allowFailure: false,
    });

    await VM.executeMulticall(calls);
}
