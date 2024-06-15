import { TapiocaMulticall } from '@typechain/index';
import { createEmptyStratYbAsset__task, loadLocalContract } from 'tapioca-sdk';
import { TTapiocaDeployerVmPass } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { deployPostLbpStack__task__loadContracts__generic } from '../2-deployPostLbpStack';
import { DEPLOYMENT_NAMES, DEPLOY_CONFIG } from '../DEPLOY_CONFIG';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { BigNumber, BigNumberish } from 'ethers';
import { ERC20 } from '@typechain/@openzeppelin/contracts/token/ERC20';

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
    const { tag } = taskArgs;

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

    let tapAssetId: BigNumber = hre.ethers.BigNumber.from(0);
    let wethAssetId: BigNumber = hre.ethers.BigNumber.from(0);

    try {
        const tapTokenEmptyStrat = loadLocalContract(
            hre,
            chainInfo.chainId,
            DEPLOYMENT_NAMES.TAP_TOKEN_YB_EMPTY_STRAT,
            taskArgs.tag,
        );
        const wethEmptyStrat = loadLocalContract(
            hre,
            chainInfo.chainId,
            DEPLOYMENT_NAMES.WETH_YB_EMPTY_STRAT,
            taskArgs.tag,
        );

        tapAssetId = await yieldbox.ids(
            1,
            tapToken.address,
            tapTokenEmptyStrat.address,
            0,
        );
        wethAssetId = await yieldbox.ids(
            1,
            DEPLOY_CONFIG.MISC[chainInfo.chainId]!.WETH!,
            wethEmptyStrat.address,
            0,
        );
    } catch (e) {}

    // Used in Bar Penrose register
    {
        if (tapAssetId.eq(0)) {
            await createEmptyStratYbAsset__task(
                {
                    ...taskArgs,
                    token: tapToken.address,
                    deploymentName: DEPLOYMENT_NAMES.TAP_TOKEN_YB_EMPTY_STRAT,
                },
                hre,
            );
        }

        if (wethAssetId.eq(0)) {
            await createEmptyStratYbAsset__task(
                {
                    ...taskArgs,
                    token: DEPLOY_CONFIG.MISC[chainInfo.chainId]!.WETH!,
                    deploymentName: DEPLOYMENT_NAMES.WETH_YB_EMPTY_STRAT,
                },
                hre,
            );
        }
    }

    {
        const tapYbBalance = await yieldbox.balanceOf(
            tapiocaMulticallAddr,
            tapAssetId,
        );
        const wethYbBalance = await yieldbox.balanceOf(
            tapiocaMulticallAddr,
            wethAssetId,
        );

        if (tapYbBalance.eq(0)) {
            const toDeposit = hre.ethers.utils.parseEther('1');
            console.log('[+] Init deposit', toDeposit, 'WETH in YB');

            // Tap deposit
            approveAndDepositAssetYB(
                hre,
                yieldbox.address,
                tapToken.address,
                DEPLOYMENT_NAMES.TAP_TOKEN_YB_EMPTY_STRAT,
                toDeposit,
                tapiocaMulticallAddr,
                calls,
                tag,
            );
        }

        // Weth deposit
        if (wethYbBalance.eq(0)) {
            const toDeposit = hre.ethers.utils.parseEther('0.0001');
            console.log('[+] Init deposit', toDeposit, 'WETH in YB');
            approveAndDepositAssetYB(
                hre,
                yieldbox.address,
                DEPLOY_CONFIG.MISC[chainInfo.chainId]!.WETH!,
                DEPLOYMENT_NAMES.WETH_YB_EMPTY_STRAT,
                toDeposit,
                tapiocaMulticallAddr,
                calls,
                tag,
            );
        }
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

export async function approveAndDepositAssetYB(
    hre: HardhatRuntimeEnvironment,
    yieldbox: string,
    token: string,
    stratName: string,
    amount: BigNumberish,
    tapiocaMulticallAddr: string,
    calls: TapiocaMulticall.CallStruct[],
    tag: string,
) {
    const yieldboxContract = await hre.ethers.getContractAt(
        'YieldBox',
        yieldbox,
    );
    const strat = loadLocalContract(
        hre,
        hre.SDK.chainInfo.chainId,
        stratName,
        tag,
    ).address;

    const tokenContract = (await hre.ethers.getContractAt(
        '@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20',
        token,
    )) as ERC20;
    const asset = await yieldboxContract.ids(1, token, strat, 0);

    calls.push(
        {
            target: token,
            callData: tokenContract.interface.encodeFunctionData('approve', [
                yieldbox,
                amount,
            ]),
            allowFailure: false,
        },
        {
            target: yieldbox,
            callData: yieldboxContract.interface.encodeFunctionData(
                'depositAsset',
                [asset, tapiocaMulticallAddr, tapiocaMulticallAddr, amount, 0],
            ),
            allowFailure: false,
        },
    );
}
