import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { TTapiocaDeployTaskArgs } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { postDeploySetupLbp2 } from './postDeploy/0-postDeploySetupLbp2';

/**
 * @notice Called after `deployLbp__task`
 *
 * Post Deploy Setup:
 * - Set swap enabled on LBP
 */
export const deployLbp__2__task = async (
    _taskArgs: TTapiocaDeployTaskArgs & {
        ltapAmount: string;
        usdcAmount: string;
        startTimestamp: string;
    },
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        { hre, staticSimulation: false },
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        async () => {},
        postDeploySetupLbp2,
    );
};
