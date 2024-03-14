import { scope, types } from 'hardhat/config';
import { deployPreLbpStack__task } from 'tasks/deploy/1-deployPreLbpStack';
import { deployPostLbpStack__task } from 'tasks/deploy/2-deployPostLbpStack';
import { deployERC20Mock__task } from 'tasks/deploy/mock/deployERC20Mock';
import { TAP_TASK } from 'tapioca-sdk';
import { deployUniV3pool__task } from 'tasks/deploy/misc/deployUniV3Pool';

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
        .addParam('name', 'The name of the ERC20 token to deploy.')
        .addOptionalParam(
            'decimals',
            'The number of decimals for the token.',
            18,
            types.int,
        ),
);
TAP_TASK(
    deployScope
        .task('uniV3Pool', 'Deploy a UniV3 pool', deployUniV3pool__task)
        .addOptionalParam(
            'feeTier',
            'The fee tier for the pool. Default is 3000.',
            3000,
            types.int,
        ),
);
