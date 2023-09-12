import { loadFixture, time } from '@nomicfoundation/hardhat-network-helpers';
import hre from 'hardhat';
import { register } from './test.utils';
import { expect } from 'chai';

let runTestMainnet: any = (fn: () => any) =>
    describe('Seer only mainnet/arb fork', fn);
if (hre.network.config.chainId !== 1)
    runTestMainnet = (fn: () => any) => describe.skip('Seer mainnet', fn);

let runTestArb: any = (fn: () => any) =>
    describe.skip('Seer only mainnet/arb fork', fn);
if (hre.network.config.chainId !== 42161)
    runTestArb = (fn: () => any) => describe.skip('Seer arbitrum', fn);

// Tests are expected to be done on forked mainnet
runTestMainnet(() => {
    it('DAI/USDC', async () => {
        const { deployer } = await loadFixture(register);

        const seer = await (
            await hre.ethers.getContractFactory('Seer')
        ).deploy(
            'DAI/USDC', // Name
            'DAI/USDC', // Symbol
            18, // Decimals
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
            hre.ethers.utils.formatBytes32String('DAI/USDC'), // Description,
            hre.ethers.constants.AddressZero,
            deployer.address, // Owner
        );

        console.log(
            hre.ethers.utils.formatUnits(
                (await seer.peek('0x00')).rate,
                await seer.decimals(),
            ),
        );
    });

    it('ETH/USDC', async () => {
        const { deployer } = await loadFixture(register);

        const seer = await (
            await hre.ethers.getContractFactory('Seer')
        ).deploy(
            'ETH/USDC', // Name
            'ETH/USDC', // Symbol
            18, // Decimals
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
            hre.ethers.utils.formatBytes32String('ETH/USDC'), // Description,
            hre.ethers.constants.AddressZero,
            deployer.address, // Owner
        );

        console.log(
            hre.ethers.utils.formatUnits(
                (await seer.peek('0x00')).rate,
                await seer.decimals(),
            ),
        );
    });

    it('TriCrypto', async () => {
        const { deployer } = await loadFixture(register);

        const seer = await (
            await hre.ethers.getContractFactory('ARBTriCryptoOracle')
        ).deploy(
            'TriCrypto', // Name
            'TriCrypto', // Symbol
            '0xD51a44d3FaE010294C616388b506AcdA1bfAAE46', // TriCrypto
            '0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c', // BTC feed
            '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', // ETH feed
            '0x3E7d1eAB13ad0104d2750B8863b489D65364e32D', // USDT feed
            '0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23', // WBTC feed
            hre.ethers.constants.AddressZero, // No sequencer
            deployer.address, // Owner
        );

        await seer.grantRole(
            await seer.GUARDIAN_ROLE_CHAINLINK(),
            deployer.address,
        );
        await seer.changeStalePeriod(8640000); // just for test purposes
        console.log(
            hre.ethers.utils.formatUnits(
                (await seer.peek('0x00')).rate,
                await seer.decimals(),
            ),
        );
    });

    it('SGL ETH/USD LP', async () => {
        const { deployer } = await loadFixture(register);

        const seer = await (
            await hre.ethers.getContractFactory('SGOracle')
        ).deploy(
            'sgETH/USD', // Name
            'sgETH/USD', // Symbol
            '0x101816545F6bd2b1076434B54383a1E633390A2E', // SG ETH/USD vault
            '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', // ETH feed
            hre.ethers.constants.AddressZero, // No sequencer
            deployer.address, // Owner
        );

        await seer.grantRole(
            await seer.GUARDIAN_ROLE_CHAINLINK(),
            deployer.address,
        );
        await seer.changeStalePeriod(8640000); // just for test purposes
        console.log(
            hre.ethers.utils.formatUnits(
                (await seer.peek('0x00')).rate,
                await seer.decimals(),
            ),
        );
    });

    it('Should not revert if the sequencer does not exist', async () => {
        const { deployer } = await loadFixture(register);

        const sequencer = await (
            await hre.ethers.getContractFactory('SequencerFeedMock')
        ).deploy();

        await sequencer.setLatestRoundData({
            answer: 0, // 0 up, 1 down
            roundId: 0,
            startedAt: (await hre.ethers.provider.getBlock('latest')).timestamp, // last upbeat
            updatedAt: 0,
            answeredInRound: 0,
        });

        const seer = await (
            await hre.ethers.getContractFactory('Seer')
        ).deploy(
            'DAI/USDC', // Name
            'DAI/USDC', // Symbol
            18, // Decimals
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
            hre.ethers.utils.formatBytes32String('DAI/USDC'), // Description,
            hre.ethers.constants.AddressZero,
            deployer.address, // Owner
        );

        // Oracle doesn't exist, should not revert
        expect((await seer.peek('0x00')).rate).to.not.be.reverted;
    });

    it('Should revert if the Sequencer is down or stale', async () => {
        const { deployer } = await loadFixture(register);

        const sequencer = await (
            await hre.ethers.getContractFactory('SequencerFeedMock')
        ).deploy();

        const seer = await (
            await hre.ethers.getContractFactory('Seer')
        ).deploy(
            'DAI/USDC', // Name
            'DAI/USDC', // Symbol
            18, // Decimals
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
            hre.ethers.utils.formatBytes32String('DAI/USDC'), // Description,
            sequencer.address,
            deployer.address, // Owner
        );

        // Set the sequencer to be down
        await sequencer.setLatestRoundData({
            answer: 1, // 0 up, 1 down
            roundId: 0,
            startedAt: (await hre.ethers.provider.getBlock('latest')).timestamp, // last upbeat
            updatedAt: 0,
            answeredInRound: 0,
        });

        await expect(seer.peek('0x00')).to.be.revertedWithCustomError(
            seer,
            'SequencerDown',
        );

        // Set the sequencer to be up but stale
        await sequencer.setLatestRoundData({
            answer: 0, // 0 up, 1 down
            roundId: 0,
            startedAt: (await hre.ethers.provider.getBlock('latest')).timestamp, // last upbeat
            updatedAt: 0,
            answeredInRound: 0,
        });

        // Should revert, grace period not over
        await expect(seer.peek('0x00')).to.be.revertedWithCustomError(
            seer,
            'GracePeriodNotOver',
        );

        // Set grace period to be over
        await time.increase((await seer.GRACE_PERIOD_TIME()).add(1));
        await expect(seer.peek('0x00')).to.not.be.reverted;
    });
});

runTestArb(() => {
    it('GLP', async () => {
        const { deployer } = await loadFixture(register);

        const seer = await (
            await hre.ethers.getContractFactory('GLPOracle')
        ).deploy(
            '0x3963FfC9dff443c2A94f21b129D429891E32ec18', // GLP Manager
            '0xFdB631F5EE196F0ed6FAa767959853A9F217697D', // Arbitrum mainnet chainlink sequence uptime feed
            deployer.address, // Owner
        );

        console.log((await seer.peek('0x00')).rate);
        console.log(
            hre.ethers.utils.formatUnits(
                (await seer.peek('0x00')).rate,
                await seer.decimals(),
            ),
        );
    });
});
