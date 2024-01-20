import { HardhatRuntimeEnvironment } from 'hardhat/types';
import _ from 'lodash';
import inquirer from 'inquirer';
import { TContract } from '@tapioca-sdk/shared';

import PenroseArtifact from '@tapioca-sdk/artifacts/tapioca-bar/Penrose.json';
import USDOArtifact from '@tapioca-sdk/artifacts/tapioca-bar/USDO.json';
import OriginsArtifact from '@tapioca-sdk/artifacts/tapioca-bar/Origins.json';
import BigBangArtifact from '@tapioca-sdk/artifacts/tapioca-bar/BigBang.json';
import SingularityArtifact from '@tapioca-sdk/artifacts/tapioca-bar/Singularity.json';
import TapOFTArtifact from '@tapioca-sdk/artifacts/tap-token/TapOFT.json';
import {
    BigBang,
    Origins,
    Penrose,
    Singularity,
    USDO,
} from '@tapioca-sdk/typechain/Tapioca-bar';
import { TapOFT } from '@tapioca-sdk/typechain/tap-token';

export const pauseAll__task = async (
    taskArgs: { val: boolean },
    hre: HardhatRuntimeEnvironment,
) => {
    //pausable contracts with `updatePause(bool val)`: USDO, TapOFT, Penrose
    //pausable contracts with  `updatePauseAll(bool val, bool resetAccrueTimestmap)`: Singularity
    //pausable contracts with  `updatePauseAll(PauseType _type, bool val)`: BigBang, Origins

    const chainInfo = hre.SDK.utils.getChainBy(
        'chainId',
        await hre.getChainId(),
    );
    if (!chainInfo) throw new Error('Chain not found');

    const startsWith = ['BigBang', 'Tapioca Singularity'];
    const fixedNames = ['USDO', 'TapOFT', 'Penrose', 'Origins'];
    const tag = await hre.SDK.hardhatUtils.askForTag(hre, 'local');
    const signer = (await hre.ethers.getSigners())[0];

    const filter = (a: TContract) => {
        if (a.name == 'Cluster') return false;

        if (fixedNames.indexOf(a.name) > -1) return true;

        for (let i = 0; i < startsWith.length; i++) {
            if (a.name.startsWith(startsWith[i])) return true;
        }
    };
    const allContracts = loadAllContracts(
        hre,
        tag,
        await hre.getChainId(),
        filter,
    );

    const bigBangMarkets = allContracts
        .filter((a) => a.name.startsWith('BigBang'))
        .map(
            (a) =>
                new hre.ethers.Contract(
                    a.address,
                    BigBangArtifact.abi,
                    signer,
                ).connect(signer) as BigBang,
        );
    const sglMarkets = allContracts
        .filter((a) => a.name.startsWith('Tapioca Singularity'))
        .map(
            (a) =>
                new hre.ethers.Contract(
                    a.address,
                    SingularityArtifact.abi,
                    signer,
                ).connect(signer) as Singularity,
        );

    const usdo = new hre.ethers.Contract(
        allContracts.filter((a) => a.name == 'USDO')[0].address,
        USDOArtifact.abi,
        signer,
    ).connect(signer) as USDO;
    const penrose = new hre.ethers.Contract(
        allContracts.filter((a) => a.name == 'Penrose')[0].address,
        PenroseArtifact.abi,
        signer,
    ).connect(signer) as Penrose;
    const origins = new hre.ethers.Contract(
        allContracts.filter((a) => a.name == 'Origins')[0].address,
        OriginsArtifact.abi,
        signer,
    ).connect(signer) as Origins;
    const tapOft = new hre.ethers.Contract(
        allContracts.filter((a) => a.name == 'TapOFT')[0].address,
        TapOFTArtifact.abi,
        signer,
    ).connect(signer) as TapOFT;

    if (!taskArgs.val) {
        //update Penrose first
        (await penrose.updatePause(taskArgs.val)).wait(3);
    }

    //pause BigBang markets
    if (bigBangMarkets.length > 0) {
        const bbPauseFn = bigBangMarkets[0].interface.encodeFunctionData(
            'updatePauseAll',
            [taskArgs.val],
        );
        await penrose.executeMarketFn(
            bigBangMarkets.map((a) => a.address),
            bigBangMarkets.map((a) => bbPauseFn),
            true,
        );
    }

    //pause Singularity markets
    if (sglMarkets.length > 0) {
        const sglPauseFn = sglMarkets[0].interface.encodeFunctionData(
            'updatePauseAll',
            [taskArgs.val, true],
        );
        await penrose.executeMarketFn(
            sglMarkets.map((a) => a.address),
            sglMarkets.map((a) => sglPauseFn),
            true,
        );
    }

    //pause Origins
    (await origins.updatePauseAll(taskArgs.val)).wait(3);

    //pause USDO
    (await usdo.updatePause(taskArgs.val)).wait(3);

    //pause TapOFT
    (await tapOft.updatePause(taskArgs.val)).wait(3);

    if (taskArgs.val) {
        //pause Penrose last
        (await penrose.updatePause(taskArgs.val)).wait(3);
    }

    //TBD: multicall won't work because it doesn't have permissions to execute pause
    //    //retrieve Multicall contract
    // const multicall = hre.SDK.db
    //     .loadGlobalDeployment(
    //         tag,
    //         hre.SDK.config.TAPIOCA_PROJECTS_NAME.Generic,
    //         chainInfo.chainId,
    //     )
    //     .filter((a) => a.name == 'Multicall3')[0];
    // if (!multicall) throw new Error('Multicall3 not found');

    // const calls = [];
};

const buildMulticallData = (target: string, data: string) => {
    return {
        target,
        allowFailure: false,
        callData: data,
    };
};

const loadAllContracts = (
    hre: HardhatRuntimeEnvironment,
    tag: any,
    chain: any,
    filter: any,
) => {
    const contracts = loadContractsFromProject(
        hre,
        tag,
        chain,
        hre.SDK.config.TAPIOCA_PROJECTS_NAME.TapiocaBar,
        filter,
    );
    contracts.push(
        ...loadContractsFromProject(
            hre,
            tag,
            chain,
            hre.SDK.config.TAPIOCA_PROJECTS_NAME.TapToken,
            filter,
        ),
    );
    contracts.push(
        ...loadContractsFromProject(
            hre,
            tag,
            chain,
            hre.SDK.config.TAPIOCA_PROJECTS_NAME.Generic,
            filter,
        ),
    );
    return contracts;
};

const loadContractsFromProject = (
    hre: HardhatRuntimeEnvironment,
    tag: any,
    chain: any,
    projectName: any,
    filter: any,
) => {
    return hre.SDK.db
        .loadGlobalDeployment(tag, projectName, chain)
        .filter(filter);
};
