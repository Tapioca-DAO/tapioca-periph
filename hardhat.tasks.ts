import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { deployOracle__task } from './tasks/deploy/deployContract';

task(
    'deployOracle',
    'Deploys an oracle contract with a deterministic address, with MulticallV3.',
    deployOracle__task,
).addFlag('load', 'Load the contracts from the local database.');
