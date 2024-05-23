import { checkExists } from 'tapioca-sdk';
import { TTapiocaDeployerVmPass } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { DEPLOYMENT_NAMES } from '../DEPLOY_CONFIG';

export async function setupAddClusterAddresses(
    params: TTapiocaDeployerVmPass<unknown>,
) {
    const { hre, VM } = params;

    const cluster = await hre.ethers.getContractAt(
        'Cluster',
        checkExists(
            hre,
            VM.list().find((dep) => dep.name === DEPLOYMENT_NAMES.CLUSTER),
            DEPLOYMENT_NAMES.CLUSTER,
            'This',
        ).address,
    );

    const magnetarAddr = checkExists(
        hre,
        VM.list().find((dep) => dep.name === DEPLOYMENT_NAMES.MAGNETAR),
        DEPLOYMENT_NAMES.MAGNETAR,
        'This',
    ).address;

    if (
        (await cluster.isWhitelisted(
            hre.SDK.chainInfo.lzChainId,
            magnetarAddr,
        )) !== true
    ) {
        console.log(
            `[+] Whitelisting Magnetar ${magnetarAddr} in Cluster ${cluster.address}`,
        );
        await VM.executeMulticall([
            {
                target: cluster.address,
                callData: cluster.interface.encodeFunctionData(
                    'updateContract',
                    [0, magnetarAddr, true],
                ),
                allowFailure: false,
            },
        ]);
    }
}
