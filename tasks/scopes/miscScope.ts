import { scope } from 'hardhat/config';
import { deploySwappers__task } from 'tasks/deploy/misc/deploySwapper';
import { pauseAll__task } from 'tasks/exec/misc/pause-all';

const miscScope = scope('extra', ' Miscellaneous tasks');

miscScope
    .task('pauseAll', 'Pause all contracts', pauseAll__task)
    .addFlag('val', 'true (pause) / false (unpause)');

miscScope.task(
    'deploySwapper',
    'Deploys a swapper contract with a deterministic address, with MulticallV3.',
    deploySwappers__task,
);
