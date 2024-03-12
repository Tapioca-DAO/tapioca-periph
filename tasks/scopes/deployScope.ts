import { scope } from 'hardhat/config';
import { deployPreLbpStack__task } from 'tasks/deploy/1-deployPreLbpStack';
import { deployPostLbpStack__task } from 'tasks/deploy/2-deployPostLbpStack';
import { deployERC20Mock__task } from 'tasks/deploy/mock/deployERC20Mock';

const deployScope = scope('deploys', 'Deployment tasks');

deployScope
    .task(
        'preLbp',
        'Deploy Cluster, Pearlmit and Magnetar',
        deployPreLbpStack__task,
    )
    .addOptionalParam(
        'tag',
        'The tag to use for the deployment. Defaults to "default" if not specified.',
        'default',
    )
    .addFlag(
        'load',
        'Load the contracts from the database instead of building them.',
    )
    .addFlag('verify', 'Add to verify the contracts after deployment.');

deployScope
    .task('postLbp', 'Deploy Oracles', deployPostLbpStack__task)
    .addOptionalParam(
        'tag',
        'The tag to use for the deployment. Defaults to "default" if not specified.',
        'default',
    )
    .addFlag(
        'load',
        'Load the contracts from the database instead of building them.',
    )
    .addFlag('verify', 'Add to verify the contracts after deployment.');

deployScope
    .task('erc20mock', 'Deploy an ERC20 Mock', deployERC20Mock__task)
    .addParam('name', 'The name of the ERC20 token to deploy.')
    .addOptionalParam(
        'tag',
        'The tag to use for the deployment. Defaults to "default" if not specified.',
        'default',
    )
    .addFlag(
        'load',
        'Load the contracts from the database instead of building them.',
    )
    .addFlag('verify', 'Add to verify the contracts after deployment.');
