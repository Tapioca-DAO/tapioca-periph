import hre, { ethers } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { BN, register, registerFork } from './test.utils';

describe.only('Seer', () => {
    it('test', async () => {
        const {
            deployer,
            eoa1,
            yieldBox,
            createTokenEmptyStrategy,
            deployCurveStableToUsdoBidder,
            usd0,
            bar,
            __wethUsdcPrice,
            wethUsdcOracle,
            weth,
            wethAssetId,
            mediumRiskMC,
            usdc,
            magnetar,
            initContracts,
            timeTravel,
        } = await loadFixture(register);

        const chainLinkAggr = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';
        const uniV3Pool = '0x11b815efB8f581194ae79006d24E0d814B7697F6';
        const seer = await (
            await hre.ethers.getContractFactory('Seer')
        ).deploy('ETH/USD', 'ETH/USD', chainLinkAggr, uniV3Pool);

        console.log((await seer.getPrice()).div(1e8));
        console.log((await seer.getUniPrice()).div(1e6));
    });
});
