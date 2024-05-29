import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

import { DEPLOYMENT_NAMES } from '../deploy/DEPLOY_CONFIG';
import {
    YieldBoxURIBuilder__factory,
    YieldBox__factory,
} from '@typechain/index';

// TODO - Put WETH9 in params for prod
export const buildYieldBox = async (
    hre: HardhatRuntimeEnvironment,
    weth: string,
): Promise<
    [
        IDeployerVMAdd<YieldBoxURIBuilder__factory>,
        IDeployerVMAdd<YieldBox__factory>,
    ]
> => {
    const YieldBoxURIBuilder = await hre.ethers.getContractFactory(
        'YieldBoxURIBuilder',
    );

    const YieldBox = await hre.ethers.getContractFactory('YieldBox');

    return [
        {
            contract: YieldBoxURIBuilder,
            deploymentName: DEPLOYMENT_NAMES.YieldBoxURIBuilder,
            args: [],
        },
        {
            contract: YieldBox,
            deploymentName: DEPLOYMENT_NAMES.YieldBox,
            args: [
                weth,
                // YieldBoxURIBuilder, to be replaced by VM
                hre.ethers.constants.AddressZero,
            ],
            dependsOn: [
                { argPosition: 1, deploymentName: 'YieldBoxURIBuilder' },
            ],
        },
    ];
};
