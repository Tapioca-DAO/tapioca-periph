import { HardhatRuntimeEnvironment } from 'hardhat/types';
import _ from 'lodash';
import inquirer from 'inquirer';

export const setClusterOnMagnetar__task = async (
    {},
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

    const { cluster } = await inquirer.prompt({
        type: 'input',
        name: 'cluster',
        message: 'Cluster address',
    });

    await (await magnetar.setCluster(cluster)).wait(3);
};
