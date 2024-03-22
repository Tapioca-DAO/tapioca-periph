import { scope } from 'hardhat/config';
import { TAP_TASK } from 'tapioca-sdk';
import { testnet__deployLiquidityInPool__task } from 'tasks/deploy/testnet/deployLiquidityInPool';

const testScope = scope('testScope', 'Testing tasks');

TAP_TASK(
    testScope.task(
        'deployLiquidityInPool',
        'Deploys a UniV3 pool with fresh mock tokens. Deploys an Arrakis pool and adds liquidity to it.',
        testnet__deployLiquidityInPool__task,
    ),
);
