import { TapiocaMulticall } from '@typechain/index';
import { createEmptyStratYbAsset__task, loadLocalContract } from 'tapioca-sdk';
import { TTapiocaDeployerVmPass } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { deployPostLbpStack__task__loadContracts__generic } from '../2-deployPostLbpStack';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from '../DEPLOY_CONFIG';

export async function deployPostLbpStack__postDeploy(
    params: TTapiocaDeployerVmPass<{
        ratioTap: number;
        ratioWeth: number;
        amountTap: string;
        amountWeth: string;
    }>,
) {
    const { hre, VM, isTestnet, isHostChain } = params;

    const calls: TapiocaMulticall.CallStruct[] = [];

    await pushCallsCreateTapAndWethYbAssetsAndDeposit(params, calls);
    await pushCallsTestnetUpdateStaleness(params, calls);

    await VM.executeMulticall(calls);
}

async function pushCallsCreateTapAndWethYbAssetsAndDeposit(
    params: TTapiocaDeployerVmPass<{
        ratioTap: number;
        ratioWeth: number;
        amountTap: string;
        amountWeth: string;
    }>,
    calls: TapiocaMulticall.CallStruct[],
) {
    const { hre, tapiocaMulticallAddr, taskArgs, chainInfo } = params;

    const { tapToken } = deployPostLbpStack__task__loadContracts__generic(
        hre,
        taskArgs.tag,
    );
    const yieldbox = await hre.ethers.getContractAt(
        'YieldBox',
        loadLocalContract(
            hre,
            chainInfo.chainId,
            DEPLOYMENT_NAMES.YIELDBOX,
            taskArgs.tag,
        ).address,
    );

    // Used in Bar Penrose register
    await createEmptyStratYbAsset__task(
        {
            ...taskArgs,
            token: tapToken.address,
            deploymentName: DEPLOYMENT_NAMES.TAP_TOKEN_YB_EMPTY_STRAT,
        },
        hre,
    );

    await createEmptyStratYbAsset__task(
        {
            ...taskArgs,
            token: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.WETH!,
            deploymentName: DEPLOYMENT_NAMES.WETH_YB_EMPTY_STRAT,
        },
        hre,
    );
    {
        const tapAssetStrat = loadLocalContract(
            hre,
            chainInfo.chainId,
            DEPLOYMENT_NAMES.TAP_TOKEN_YB_EMPTY_STRAT,
            taskArgs.tag,
        );
        const wethAssetStrat = loadLocalContract(
            hre,
            chainInfo.chainId,
            DEPLOYMENT_NAMES.WETH_YB_EMPTY_STRAT,
            taskArgs.tag,
        );

        const tapAsset = await yieldbox.ids(
            1,
            tapToken.address,
            tapAssetStrat.address,
            0,
        );
        const wethAsset = await yieldbox.ids(
            1,
            DEPLOY_CONFIG.MISC[chainInfo.chainId]!.WETH!,
            wethAssetStrat.address,
            0,
        );

        const tapTokenContract = await hre.ethers.getContractAt(
            'ERC20',
            tapToken.address,
        );
        const amount = hre.ethers.utils.parseEther('1');

        calls.push(
            {
                target: tapToken.address,
                callData: tapTokenContract.interface.encodeFunctionData(
                    'approve',
                    [yieldbox.address, amount],
                ),
                allowFailure: false,
            },
            {
                target: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.WETH!,
                callData: tapTokenContract.interface.encodeFunctionData(
                    'approve',
                    [yieldbox.address, amount],
                ),
                allowFailure: false,
            },

            {
                target: yieldbox.address,
                callData: yieldbox.interface.encodeFunctionData(
                    'depositAsset',
                    [
                        tapAsset,
                        tapiocaMulticallAddr,
                        tapiocaMulticallAddr,
                        amount,
                        0,
                    ],
                ),
                allowFailure: false,
            },

            {
                target: yieldbox.address,
                callData: yieldbox.interface.encodeFunctionData(
                    'depositAsset',
                    [
                        wethAsset,
                        tapiocaMulticallAddr,
                        tapiocaMulticallAddr,
                        amount,
                        0,
                    ],
                ),
                allowFailure: false,
            },
        );
    }
}

async function pushCallsTestnetUpdateStaleness(
    params: TTapiocaDeployerVmPass<{
        ratioTap: number;
        ratioWeth: number;
        amountTap: string;
        amountWeth: string;
    }>,
    calls: TapiocaMulticall.CallStruct[],
) {
    const { hre, VM, isTestnet, isHostChain } = params;

    // Set staleness on testnet
    // isTestnet ? 4294967295 : 86400, // CL stale period, 1 day on prod. max uint32 on testnet
    if (isTestnet) {
        const contracts = VM.list();
        const findContract = (name: string) =>
            contracts.find((e) => e.name === name);

        const chainLinkUtils = await hre.ethers.getContractAt(
            'ChainlinkUtils',
            '',
        );

        if (isHostChain) {
            const ethSeerCl = findContract(DEPLOYMENT_NAMES.ETH_SEER_CL_ORACLE);
            const ethUniCl = findContract(DEPLOYMENT_NAMES.ETH_SEER_UNI_ORACLE);
            const tap = findContract(DEPLOYMENT_NAMES.TAP_ORACLE);
            const adbTapOption = findContract(
                DEPLOYMENT_NAMES.ADB_TAP_OPTION_ORACLE,
            );
            const tobTapOption = findContract(
                DEPLOYMENT_NAMES.TOB_TAP_OPTION_ORACLE,
            );
            const reth = findContract(
                DEPLOYMENT_NAMES.RETH_USD_SEER_CL_MULTI_ORACLE,
            );
            const wsteth = findContract(
                DEPLOYMENT_NAMES.WSTETH_USD_SEER_CL_MULTI_ORACLE,
            );

            const stalenessToSet = [
                ethSeerCl,
                ethUniCl,
                tap,
                adbTapOption,
                tobTapOption,
                reth,
                wsteth,
            ];

            for (const contract of stalenessToSet) {
                if (contract) {
                    calls.push({
                        target: contract.address,
                        callData: chainLinkUtils.interface.encodeFunctionData(
                            'changeDefaultStalePeriod',
                            [4294967295],
                        ),
                        allowFailure: false,
                    });
                }
            }
        }
    }
}
