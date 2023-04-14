import { ethers } from 'hardhat';
import { expect } from 'chai';
import {
    ContractThatReverts__factory,
    TapiocaDeployerMock__factory,
    ContractThatCannotBeDeployed__factory,
} from '../gitsub_tapioca-sdk/src/typechain/tapioca-mocks/factories';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { register } from './test.utils';

import { Multicall3 } from '../typechain';

describe('Multicall test', () => {
    it('should test revert string', async () => {
        const { deployer } = await loadFixture(register);

        const ContractThatReverts = new ContractThatReverts__factory(deployer);
        const revertContract = await ContractThatReverts.deploy();

        const multiCall = await (
            await ethers.getContractFactory('Multicall3')
        ).deploy();
        await multiCall.deployed();

        const calls: Multicall3.CallStruct[] = [];
        const callData = revertContract.interface.encodeFunctionData(
            'shouldRevert',
            [1],
        );

        calls.push({
            target: revertContract.address,
            allowFailure: false,
            callData,
        });
        await expect(multiCall.multicall(calls)).to.be.revertedWith(
            await revertContract.revertStr(),
        );
    });

    it('should test revert string through TapiocaDeployer', async () => {
        const { deployer } = await loadFixture(register);

        const TapiocaDeployerMock = new TapiocaDeployerMock__factory(deployer);

        const tapiocaDeployer = await TapiocaDeployerMock.deploy();
        await tapiocaDeployer.deployed();

        const multiCall = await (
            await ethers.getContractFactory('Multicall3')
        ).deploy();

        const ContractThatCannotBeDeployed =
            new ContractThatCannotBeDeployed__factory(deployer);
        const contract = {
            contract: ContractThatCannotBeDeployed,
            deploymentName: 'ContractThatCannotBeDeployed',
            args: [],
        };

        const creationCode =
            contract.contract.bytecode +
            contract.contract.interface
                .encodeDeploy(contract.args)
                .split('x')[1];
        const salt = ethers.utils.solidityKeccak256(['string'], ['RandomSalt']);

        const callData = tapiocaDeployer.interface.encodeFunctionData(
            'deploy',
            [0, salt, creationCode, 'ContractThatCannotBeDeployed'],
        );

        const calls: Multicall3.CallStruct[] = [];
        calls.push({
            target: tapiocaDeployer.address,
            allowFailure: false,
            callData,
        });

        await expect(multiCall.multicall(calls)).to.be.revertedWith(
            'Create2: Failed deploying contract ContractThatCannotBeDeployed',
        );
    });
});
