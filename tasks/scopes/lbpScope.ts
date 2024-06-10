import { scope } from 'hardhat/config';
import { TAP_TASK } from 'tapioca-sdk';
import { disableLbpSwaps__task } from 'tasks/exec/lbp/disableLbpSwaps__task';
import { exitPool__task } from 'tasks/exec/lbp/exitPool__task';

const lbpScope = scope('lbp', 'LBP setter tasks');

TAP_TASK(
    lbpScope.task(
        'disableSwaps',
        'Disable the LBP swaps',
        disableLbpSwaps__task,
    ),
);

TAP_TASK(
    lbpScope.task(
        'exitPool',
        'Exit and retrieve liquidity from the pool',
        exitPool__task,
    ),
);
