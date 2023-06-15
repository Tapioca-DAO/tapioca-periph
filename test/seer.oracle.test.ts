import hre, { ethers } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { BN, register, registerFork } from './test.utils';
// Tests are expected to be done on forked mainnet
describe.only('Seer', () => {
    it('DAI/USDC', async () => {
        const { deployer } = await loadFixture(register);

        const seer = await (
            await hre.ethers.getContractFactory('Seer')
        ).deploy(
            'DAI/USDC', // Name
            'DAI/USDC', // Symbol
            [
                '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', // DAI
                '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
            ],
            [
                '0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168', /// LP DAI/USDC
            ],
            [1], // Multiply/divide Uni
            600, // TWAP
            10, // Observation length
            0, // Uni final currency
            [
                '0xaed0c38402a5d19df6e4c03f4e2dced6e29c1ee9', // CL DAI/USD
                '0x8fffffd4afb6115b954bd326cbe7b4ba576818f6', // CL USDC/USD
            ],
            [1, 0], // Multiply/divide CL
            8640000, // CL period before stale
            [deployer.address], // Owner
            hre.ethers.utils.formatBytes32String('DAI/USDC'), // Description
        );

        console.log(
            hre.ethers.utils.formatEther((await seer.peek('0x00')).rate),
        );
    });

    it('ETH/USDC', async () => {
        const { deployer } = await loadFixture(register);

        const seer = await (
            await hre.ethers.getContractFactory('Seer')
        ).deploy(
            'ETH/USDC', // Name
            'ETH/USDC', // Symbol
            [
                '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', // ETH
                '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
            ],
            [
                '0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640', /// LP ETH/USDC
            ],
            [0], // Multiply/divide Uni
            600, // TWAP
            10, // Observation length
            0, // Uni final currency
            [
                '0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419', // CL ETH/USD
                '0x8fffffd4afb6115b954bd326cbe7b4ba576818f6', // CL USDC/USD
            ],
            [1, 0], // Multiply/divide CL
            8640000, // CL period before stale
            [deployer.address], // Owner
            hre.ethers.utils.formatBytes32String('ETH/USDC'), // Description
        );

        console.log(
            hre.ethers.utils.formatEther((await seer.peek('0x00')).rate),
        );
    });
});
