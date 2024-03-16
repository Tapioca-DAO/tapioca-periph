import { scope } from 'hardhat/config';
import { instantRedeemLocalOnLbpHelper__task } from 'tasks/exec/lbp/lbp-instantRedeemLocal';
import { redeemLocalOnLbpHelper__task } from 'tasks/exec/lbp/lbp-redeemLocal';
import { redeemRemoteOnLbpHelper__task } from 'tasks/exec/lbp/lbp-redeemRemote';
import { retryRevertOnLbpHelper__task } from 'tasks/exec/lbp/lbp-retryRevert';

const lbpScope = scope('lbp', 'LBP setter tasks');

lbpScope.task(
    'retryRevertOnLbpHelper',
    'Retries revert on StargateLbpHelper',
    retryRevertOnLbpHelper__task,
);

lbpScope.task(
    'instantRedeemLocalOnLbpHelper',
    'Performs instantRedeemLocal on StargateLbpHelper',
    instantRedeemLocalOnLbpHelper__task,
);

lbpScope.task(
    'redeemLocalOnLbpHelper',
    'Performs redeemLocal on StargateLbpHelper',
    redeemLocalOnLbpHelper__task,
);

lbpScope.task(
    'redeemRemoteOnLbpHelper',
    'Performs redeemRemote on StargateLbpHelper',
    redeemRemoteOnLbpHelper__task,
);
