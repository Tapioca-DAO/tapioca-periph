import { scope } from 'hardhat/config';
import { deployPreLbpStack__task } from 'tasks/deploy/1-deployPreLbpStack';
import { deployPostLbpStack__task } from 'tasks/deploy/2-deployPostLbpStack';
import { deployERC20Mock__task } from 'tasks/deploy/mock/deployERC20Mock';
import { TAP_TASK } from 'tapioca-sdk';
import { deployUniV3EnvMock__task } from 'tasks/deploy/misc/deployUniV3MockEnv';

const deployScope = scope('deploys', 'Deployment tasks');

TAP_TASK(
    deployScope.task(
        'preLbp',
        'Deploy Cluster, Pearlmit and Magnetar',
        deployPreLbpStack__task,
    ),
);

TAP_TASK(
    deployScope.task('postLbp', 'Deploy Oracles', deployPostLbpStack__task),
);

TAP_TASK(
    deployScope
        .task('erc20mock', 'Deploy an ERC20 Mock', deployERC20Mock__task)
        .addParam('name', 'The name of the ERC20 token to deploy.'),
);
TAP_TASK(
    deployScope.task(
        'uniV3EnvMock',
        'Deploy a UniV3 mock infrastructure',
        deployUniV3EnvMock__task,
    ),
);
