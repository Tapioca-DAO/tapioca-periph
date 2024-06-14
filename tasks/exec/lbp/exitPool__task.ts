import { TapiocaMulticall } from '@typechain/index';
import { loadLocalContract } from 'tapioca-sdk';
import { TTapiocaDeployerVmPass } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { WeightedPoolEncoder } from '@balancer-labs/balancer-js';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';
import { deployLbp__getDeployments } from 'tasks/deploy/1-1-deployLbp';
import { TTapiocaDeployTaskArgs } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { BalancerSDK } from '@balancer-labs/sdk';

export const exitPool__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        multisigAddress: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre },
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        async () => {},
        setup,
    );
};

export async function setup(
    params: TTapiocaDeployerVmPass<{ multisigAddress: string }>,
) {
    const { hre, VM, tapiocaMulticallAddr, taskArgs, chainInfo, isTestnet } =
        params;
    const { tag, multisigAddress } = taskArgs;

    console.log('[+] Exiting LBP');

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

    const vault = await hre.ethers.getContractAt(
        'Vault',
        loadLocalContract(
            hre,
            hre.SDK.chainInfo.chainId,
            DEPLOYMENT_NAMES.LBP_VAULT,
            tag,
        ).address,
    );

    const { lTap } = deployLbp__getDeployments({ hre, tag });
    const usdc = DEPLOY_CONFIG.MISC[chainInfo.chainId]!.USDC!;

    const ltapContract = await hre.ethers.getContractAt(
        '@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20',
        lTap.address,
    );
    const usdContract = await hre.ethers.getContractAt(
        '@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20',
        usdc,
    );

    const ltapVaultBalance = await ltapContract.balanceOf(vault.address);
    const usdcVaultBalance = await usdContract.balanceOf(vault.address);
    const ownerPoolBalance = await lbp.balanceOf(tapiocaMulticallAddr);

    const slippage = 1;
    const ltapAmountWithdraw = ltapVaultBalance.sub(
        ltapVaultBalance.div(1000).mul(slippage),
    );
    const usdcAmountWithdraw = usdcVaultBalance.sub(
        usdcVaultBalance.div(1000).mul(slippage),
    );

    console.log('[+] LTAP amount to withdraw:', ltapAmountWithdraw.toString());
    console.log('[+] USDC amount to withdraw:', usdcAmountWithdraw.toString());

    calls.push(
        {
            target: lbp.address,
            callData: lbp.interface.encodeFunctionData('approve', [
                vault.address,
                hre.ethers.constants.MaxInt256,
            ]),
            allowFailure: false,
        },
        {
            target: vault.address,
            callData: vault.interface.encodeFunctionData('exitPool', [
                await lbp.getPoolId(),
                tapiocaMulticallAddr,
                multisigAddress,
                {
                    assets: [lTap.address, usdc],
                    minAmountsOut: [ltapAmountWithdraw, usdcAmountWithdraw],
                    toInternalBalance: false,
                    userData: WeightedPoolEncoder.exitBPTInForExactTokensOut(
                        [ltapAmountWithdraw, usdcAmountWithdraw],
                        ownerPoolBalance,
                    ),
                },
            ]),
            allowFailure: false,
        },
    );

    const multicall = await VM.getMulticall();
    await multicall.multicall(calls);
}
