import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { setClusterOnMagnetar__task } from './tasks/exec/01-magnetar-setCluster';
import { setHelperOnMagnetar__task } from './tasks/exec/02-magnetar-setHelper';
import { retryRevertOnLbpHelper__task } from './tasks/exec/03-lbp-retryRevert';
import { instantRedeemLocalOnLbpHelper__task } from './tasks/exec/04-lbp-instantRedeemLocal';
import { redeemLocalOnLbpHelper__task } from './tasks/exec/05-lbp-redeemLocal';
import { redeemRemoteOnLbpHelper__task } from './tasks/exec/06-lbp-redeemRemote';
import { deployOracle__task } from './tasks/deploy/deployOracle';
import { deploySwappers__task } from './tasks/deploy/deploySwapper';

task(
    'deployOracle',
    'Deploys an oracle contract with a deterministic address, with MulticallV3.',
    deployOracle__task,
).addFlag('load', 'Load the contracts from the local database.');

task(
    'setClusterOnMagnetar',
    'Sets Cluster address on Magnetar',
    setClusterOnMagnetar__task,
);

task(
    'setHelperOnMagnetar',
    'Sets MagnetarHelper address on Magnetar',
    setHelperOnMagnetar__task,
);

task(
    'retryRevertOnLbpHelper',
    'Retries revert on StargateLbpHelper',
    retryRevertOnLbpHelper__task,
);

task(
    'instantRedeemLocalOnLbpHelper',
    'Performs instantRedeemLocal on StargateLbpHelper',
    instantRedeemLocalOnLbpHelper__task,
);

task(
    'redeemLocalOnLbpHelper',
    'Performs redeemLocal on StargateLbpHelper',
    redeemLocalOnLbpHelper__task,
);

task(
    'redeemRemoteOnLbpHelper',
    'Performs redeemRemote on StargateLbpHelper',
    redeemRemoteOnLbpHelper__task,
);

task(
    'deploySwapper',
    'Deploys a swapper contract with a deterministic address, with MulticallV3.',
    deploySwappers__task,
);
