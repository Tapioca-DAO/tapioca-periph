import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { deployOracle__task } from './tasks/deploy/00-deployOracle';
import { deploySwappers__task } from './tasks/deploy/01-deploySwapper';

task(
    'deployOracle',
    'Deploys an oracle contract with a deterministic address, with MulticallV3.',
    deployOracle__task,
).addFlag('load', 'Load the contracts from the local database.');

task(
    'deploySwapper',
    'Deploys a swapper contract with a deterministic address, with MulticallV3.',
    deploySwappers__task,
);
