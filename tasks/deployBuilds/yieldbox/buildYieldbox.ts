import { IDependentOn } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import {
    YieldBoxURIBuilder__factory,
    YieldBox__factory,
} from '@typechain/index';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';

import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

// TODO - Put WETH9 in params for prod
export const buildYieldBox = async (
    hre: HardhatRuntimeEnvironment,
    weth: string,
    owner: string,
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
            deploymentName: DEPLOYMENT_NAMES.YIELD_BOX_URI_BUILDER,
            args: [],
        },
        {
            contract: YieldBox,
            deploymentName: DEPLOYMENT_NAMES.YIELDBOX,
            args: [
                weth,
                '', // YieldBoxURIBuilder, to be replaced by VM
                '', // Pearlmit, to be replaced by VM
                owner,
            ],
            dependsOn: [
                {
                    argPosition: 1,
                    deploymentName: DEPLOYMENT_NAMES.YIELD_BOX_URI_BUILDER,
                },
                {
                    argPosition: 2,
                    deploymentName: DEPLOYMENT_NAMES.PEARLMIT,
                },
            ],
        },
    ];
};
