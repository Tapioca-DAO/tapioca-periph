import { TTapiocaDeployTaskArgs } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { TapiocaMulticall } from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

export const mintMock__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        addr: string;
        amount: string;
        useMulticall?: string;
        to?: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    const { addr, amount, useMulticall, to, tag } = _taskArgs;
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });

    const token = await hre.ethers.getContractAt('ERC20Mock', addr);
    const decimals = await token.decimals();
    const parsedAmount = hre.ethers.utils.parseUnits(amount, decimals);

    console.log(
        `[+] MockERC20 minting ${amount}/${parsedAmount} wei for $${await token.name()} for:`,
    );

    if (useMulticall) {
        const calls: TapiocaMulticall.CallStruct[] = [
            {
                target: addr,
                callData: token.interface.encodeFunctionData('mintTo', [
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
    } else {
        await (await token.freeMint(parsedAmount)).wait(3);
        if (to) {
            await (await token.transfer(to, parsedAmount)).wait(3);
        }
    }
    console.log('[+] Transferred to:', to ?? (await VM.getMulticall()).address);

    console.log('[+] Tokens minted');
};
