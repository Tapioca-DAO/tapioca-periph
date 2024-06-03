import { scope, types } from 'hardhat/config';
import { TAP_TASK } from 'tapioca-sdk';
import { deployPreLbpStack__task } from 'tasks/deploy/0-deployPreLbpStack';
import { deployLbp__task } from 'tasks/deploy/1-deployLbp';
import { deployPostLbpStack__task } from 'tasks/deploy/2-deployPostLbpStack';
import { deployFinal__task } from 'tasks/deploy/3-deployFinal';
import { deployMagnetarOnly__task } from 'tasks/deploy/99-deployMagnetarOnly';
import { DEPLOY_CONFIG } from 'tasks/deploy/DEPLOY_CONFIG';
import { deployUniV3pool__task } from 'tasks/deploy/misc/deployUniV3Pool';
import { deployChainlinkFeedMock__task } from 'tasks/deploy/mock/deployChainlinkFeedMock';
import { deployERC20Mock__task } from 'tasks/deploy/mock/deployERC20Mock';
import { deployGLPManagerMock__task } from 'tasks/deploy/mock/deployGLPManagerMock';

const deployScope = scope('deploys', 'Deployment tasks');

TAP_TASK(
    deployScope
        .task(
            'lbp',
            'Deploy LBP contracts and initialize it. Called only after tap-token repo `deployLbp` task',
            deployLbp__task,
        )
        .addParam(
            'ltapAmount',
            'The amount of LTAP to be deposited in the LBP. In ether.',
        )
        .addParam(
            'usdcAmount',
            'The amount of USDC to be deposited in the LBP. In ether.',
        ),
);

TAP_TASK(
    deployScope.task(
        'preLbp',
        'Deploy Cluster, Pearlmit and Magnetar',
        deployPreLbpStack__task,
    ),
);

TAP_TASK(
    deployScope
        .task(
            'postLbp',
            'Deploy oracles. Deploy UniV3TapWeth pool and LP. Called only after tap-token repo `postLbp1` task',
            deployPostLbpStack__task,
        )
        .addParam(
            'ratioTap',
            'The ratio of TAP in the pool. Used to compute the price by dividing by ratioWeth. For example, Use 33 for `ratioTap` and `10` for `ratioWeth` to deploy a pool with 33 TAP = 10 WETH.',
        )
        .addParam(
            'ratioWeth',
            'The ratio of Weth in the pool. Used to compute the price by dividing by ratioWeth. For example, Use 33 for `ratioTap` and `10` for `ratioWeth` to deploy a pool with 33 TAP = 10 WETH.',
        )
        .addParam(
            'amountTap',
            'The amount of TAP to be deposited in the pool. In ether.',
        )
        .addParam(
            'amountWeth',
            'The amount of WETH to be deposited in the pool. In ether.',
        ),
);
TAP_TASK(
    deployScope
        .task(
            'final',
            'USDO/USDC pool deployment + Cluster whitelisting',
            deployFinal__task,
        )
        .addParam(
            'ratioUsdo',
            'The ratio of USDO in the pool. Used to compute the price by dividing by ratioUsdc. Default is 1.',
        )
        .addParam(
            'ratioUsdc',
            'The ratio of USDC in the pool. Used to compute the price by dividing by ratioUsdo. Default is 1.',
        )
        .addParam(
            'amountUsdo',
            'The amount of USDO to be deposited in the pool. In ether.',
        )
        .addParam(
            'amountUsdc',
            'The amount of USDC to be deposited in the pool. In ether.',
        ),
);

TAP_TASK(
    deployScope.task(
        'magnetar',
        'Deploys Magnetar only, expects Cluster and Pearlmit to be already deployed',
        deployMagnetarOnly__task,
    ),
);

TAP_TASK(
    deployScope
        .task('uniV3Pool', 'Deploy a UniV3 pool', deployUniV3pool__task)
        .addParam(
            'token0',
            'The address of the first token in the pool. Order does not matter.',
        )
        .addParam(
            'token1',
            'The address of the second token in the pool. Order does not matter.',
        )
        .addParam(
            'ratio0',
            'The ratio of token0 in the pool. Used to compute the price by dividing by ratio1.',
        )
        .addParam(
            'ratio1',
            'The ratio of token1 in the pool. Used to compute the price by being divided by ratio0.',
        )
        .addOptionalParam(
            'feeTier',
            'The fee tier for the pool. Default is 3000.',
            3000,
            types.int,
        ),
);

// Mocks

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
        .task(
            'chainlinkFeedMock',
            'Deploy an Chainlink feed Mock',
            deployChainlinkFeedMock__task,
        )
        .addParam('name', 'The name of the deployment.')
        .addParam('rate', 'The rate of the feed.')
        .addOptionalParam(
            'decimals',
            'The number of decimals for the token.',
            8, // Default Non-ETH pair is 8 (ex. ETH/USD). 18 for ETH pairs (ex. USD/ETH)
            types.int,
        ),
);
TAP_TASK(
    deployScope
        .task(
            'glpManagerMock',
            'Deploy a GLP Manager Mock',
            deployGLPManagerMock__task,
        )
        .addParam('name', 'The name of the deployment.')
        .addParam('glpPrice', 'The price of GLP.'),
);
