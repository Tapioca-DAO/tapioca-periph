import { scope } from 'hardhat/config';
import { TAP_TASK } from 'tapioca-sdk';
import { deployOracleMock__task } from 'tasks/exec/misc/deployOracleMock';
import { mintMock__task } from 'tasks/exec/misc/mintMock';
import { pauseAll__task } from 'tasks/exec/misc/pause-all';
import { sandbox__task } from 'tasks/exec/misc/sandbox';
import { uniPoolInfo__task } from 'tasks/exec/misc/uniPoolInfo';
import { wrapToft__task } from 'tasks/exec/misc/wrapToft';

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

TAP_TASK(
    miscScope
        .task('wrapToft', 'Wrap TOFT', wrapToft__task)
        .addParam('addr', 'The address of the token to mint')
        .addParam('amount', 'The amount to mint')
        .addOptionalParam(
            'to',
            'The address to mint to. Else caller/multicall',
        ),
);

// Sandbox
TAP_TASK(miscScope.task('sandbox', 'Sandbox', sandbox__task));

// Testnet
TAP_TASK(
    miscScope
        .task('mintMock', 'Mint mock tokens', mintMock__task)
        .addParam('addr', 'The address of the token to mint')
        .addParam('amount', 'The amount to mint')
        .addFlag(
            'useMulticall',
            'true (use multicall) / false (use EOA caller)',
        )
        .addOptionalParam(
            'to',
            'The address to mint to. Else caller/multicall',
        ),
);

TAP_TASK(
    miscScope
        .task(
            'oracleMock',
            'Deploy OracleMock contract.',
            deployOracleMock__task,
        )
        .addParam('name', 'The name of the oracle.')
        .addParam('rate', 'Rate rate, in ether (ex: "1.2" for 1.2e18).'),
);
