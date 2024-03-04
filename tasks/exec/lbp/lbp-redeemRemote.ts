import { HardhatRuntimeEnvironment } from 'hardhat/types';
import _ from 'lodash';
import inquirer from 'inquirer';

export const redeemRemoteOnLbpHelper__task = async (
    {},
    hre: HardhatRuntimeEnvironment,
) => {
    const tag = await hre.SDK.hardhatUtils.askForTag(hre, 'local');
    const dep = await hre.SDK.hardhatUtils.getLocalContract(
        hre,
        'StargateLbpHelper',
        tag,
    );
    const lbpHelper = await hre.ethers.getContractAt(
        'StargateLbpHelper',
        dep.contract.address,
    );

    const { dstChainId } = await inquirer.prompt({
        type: 'input',
        name: 'dstChainId',
        message: 'Destination LZ chain id',
        default: 0,
    });

    const { srcPoolId } = await inquirer.prompt({
        type: 'input',
        name: 'srcPoolId',
        message: 'Source LZ pool id',
        default: 0,
    });

    const { dstPoolId } = await inquirer.prompt({
        type: 'input',
        name: 'dstPoolId',
        message: 'Destination LZ pool id',
        default: 0,
    });

    const { refundAddress } = await inquirer.prompt({
        type: 'input',
        name: 'refundAddress',
        message: 'Refund address',
        default: hre.ethers.constants.AddressZero,
    });

    const { amountLP } = await inquirer.prompt({
        type: 'input',
        name: 'amountLP',
        message: 'LZ amount LP',
        default: 0,
    });

    const { minAmountLD } = await inquirer.prompt({
        type: 'input',
        name: 'minAmountLD',
        message: 'Min amount on destination',
        default: 0,
    });

    const { to } = await inquirer.prompt({
        type: 'input',
        name: 'to',
        message: 'Receiver',
        default: hre.ethers.constants.AddressZero,
    });

    const { dstGasForCall } = await inquirer.prompt({
        type: 'input',
        name: 'dstGasForCall',
        message: 'Destination gas',
        default: 0,
    });

    const { dstNativeAmount } = await inquirer.prompt({
        type: 'input',
        name: 'dstNativeAmount',
        message: 'Destination native amount',
        default: 0,
    });

    const { dstNativeAddr } = await inquirer.prompt({
        type: 'input',
        name: 'dstNativeAddr',
        message: 'Destination native address',
        default: '0x',
    });

    await (
        await lbpHelper.redeemRemote(
            dstChainId,
            srcPoolId,
            dstPoolId,
            refundAddress,
            amountLP,
            minAmountLD,
            to,
            { dstGasForCall, dstNativeAddr, dstNativeAmount },
        )
    ).wait(3);
};
