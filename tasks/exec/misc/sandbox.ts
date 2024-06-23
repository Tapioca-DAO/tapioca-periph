import { TTapiocaDeployTaskArgs } from '@tapioca-sdk/ethers/hardhat/DeployerVM';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { loadLocalContract } from 'tapioca-sdk';
import { DEPLOYMENT_NAMES } from 'tasks/deploy/DEPLOY_CONFIG';

export const sandbox__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    const { tag } = _taskArgs;
    const VM = hre.SDK.DeployerVM.loadVM({ hre, tag });
    const tapiocaMulticallAddr = await VM.getMulticall();
    const signer = (await hre.ethers.getSigners())[0];

    const cluster = await hre.ethers.getContractAt(
        'Seer',
        '0x346383F0cfb28CDB9de798cf76D50D59F1AffaeF',
    );
    console.log(await cluster.peek('0x'));

    // const ROLE = hre.ethers.utils.keccak256(
    //     hre.ethers.utils.solidityPack(['string'], ['TOE']),
    // );

    // await VM.executeMulticall([
    //     {
    //         target: cluster.address,
    //         callData: cluster.interface.encodeFunctionData('updateContract', [
    //             0,
    //             '0x6918175a68E3A6aD653AdF8Dab6322De1B5a72c1',
    //             false,
    //         ]),
    //         allowFailure: false,
    //     },
    //     {
    //         target: cluster.address,
    //         callData: cluster.interface.encodeFunctionData(
    //             'setRoleForContract',
    //             ['0x6918175a68E3A6aD653AdF8Dab6322De1B5a72c1', ROLE, false],
    //         ),
    //         allowFailure: false,
    //     },
    // ]);

    // await VM.executeMulticall([
    //     {
    //         target: cluster.address,
    //         allowFailure: false,
    //         callData: cluster.interface.encodeFunctionData('changeTwapPeriod', [
    //             30,
    //         ]),
    //     },
    // ]);
    // console.log(await usdo.get('0x', { gasLimit: 1_000_000 }));
    // console.log(await usdo.peek('0x', { gasLimit: 1_000_000 }));
    // const usdo = await hre.ethers.getContractAt(
    //     'Usdo',
    //     '0x5E0684fE3b584848096221A18B6Ee5280B654719',
    //     signer,
    // );
    // await VM.executeMulticall([
    //     {
    //         target: usdo.address,
    //         allowFailure: false,
    //         callData: usdo.interface.encodeFunctionData('setMinterStatus', [
    //             '0x6918175a68E3A6aD653AdF8Dab6322De1B5a72c1',
    //             true,
    //         ]),
    //     },
    // ]);

    // for loop to constantly send messages
};
