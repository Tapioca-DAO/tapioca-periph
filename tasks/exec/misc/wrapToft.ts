import { TTapiocaDeployTaskArgs } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { TapiocaMulticall } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const wrapToft__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        addr: string;
        amount: string;
        to?: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    const { addr, amount, to, tag } = _taskArgs;
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });

    const token = await hre.ethers.getContractAt('TOFT', addr);
    const pearlmit = await hre.ethers.getContractAt(
        'Pearlmit',
        loadLocalContract(
            hre,
            hre.SDK.chainInfo.chainId,
            DEPLOYMENT_NAMES.PEARLMIT,
            tag,
        ).address,
    );

    const wrappedToken = await hre.ethers.getContractAt(
        'ERC20Mock',
        await token.erc20(),
    );
    const decimals = await token.decimals();
    const parsedAmount = hre.ethers.utils.parseUnits(amount, decimals);

    console.log(
        `[+]  $${await token.name()} wrapping ${amount}/${parsedAmount}`,
    );

    const blockTime = await hre.ethers.provider.getBlock('latest');
    const calls: TapiocaMulticall.CallStruct[] = [
        // approve
        {
            target: wrappedToken.address,
            callData: wrappedToken.interface.encodeFunctionData('approve', [
                pearlmit.address,
                parsedAmount,
            ]),
            allowFailure: false,
        },
        {
            target: pearlmit.address,
            callData: pearlmit.interface.encodeFunctionData('approve', [
                20,
                wrappedToken.address,
                0,
                token.address,
                parsedAmount,
                blockTime.timestamp + 60, // 1 minute
            ]),
            allowFailure: false,
        },
        {
            target: addr,
            callData: token.interface.encodeFunctionData('wrap', [
                (await VM.getMulticall()).address,
                (await VM.getMulticall()).address,
                parsedAmount,
            ]),
            allowFailure: false,
        },
    ];
    if (to) {
        calls.push({
            target: addr,
            callData: token.interface.encodeFunctionData('transfer', [
                to,
                parsedAmount,
            ]),
            allowFailure: false,
        });
    }
    await VM.executeMulticall(calls);

    console.log('[+] Wrapped to:', to ?? (await VM.getMulticall()).address);
};
