import { HardhatRuntimeEnvironment } from 'hardhat/types';
import _ from 'lodash';
import inquirer from 'inquirer';

export const setHelperOnMagnetar__task = async (
    taskArgs: {},
    hre: HardhatRuntimeEnvironment,
) => {
    const tag = await hre.SDK.hardhatUtils.askForTag(hre, 'local');
    const dep = await hre.SDK.hardhatUtils.getLocalContract(
        hre,
        'Magnetar',
        tag,
    );
    const magnetar = await hre.ethers.getContractAt(
        'Magnetar',
        dep.contract.address,
    );

    const { helper } = await inquirer.prompt({
        type: 'input',
        name: 'helper',
        message: 'Helper address',
    });

    await (await magnetar.setHelper(helper)).wait(3);
};
