import { scope } from 'hardhat/config';
import { pauseAll__task } from 'tasks/exec/misc/pause-all';
import { uniPoolInfo__task } from 'tasks/exec/misc/uniPoolInfo';

const miscScope = scope('misc', ' Miscellaneous tasks');

miscScope
    .task('pauseAll', 'Pause all contracts', pauseAll__task)
    .addFlag('val', 'true (pause) / false (unpause)');

miscScope
    .task(
        'uniPoolInfo',
        'Get the information of a UniswapV3 pool. Compute the price using the sqrtPriceX96 of the pool.',
        uniPoolInfo__task,
    )
    .addParam('poolAddr', 'The address of the UniswapV3 pool');
