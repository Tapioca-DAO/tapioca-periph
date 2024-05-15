import { scope } from 'hardhat/config';
import { TAP_TASK } from 'tapioca-sdk';
import { disableLbpSwaps__task } from 'tasks/exec/lbp/disableLbpSwaps__task';

const lbpScope = scope('lbp', 'LBP setter tasks');

TAP_TASK(
    lbpScope.task(
        'disableSwaps',
        'Disable the LBP swaps',
        disableLbpSwaps__task,
    ),
);
