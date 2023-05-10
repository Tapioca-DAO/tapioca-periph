import hre, { ethers } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { BN, registerFork } from './test.utils';

describe('CurveSwapper', () => {
    describe('getOutputAmount()', () => {
        it('should get output amount', async () => {
        const { curveSwapper, usdt, usdc, createSimpleSwapData } = await loadFixture(registerFork);
        const amount = BN(1e6).mul(1000);

        const swapData = createSimpleSwapData(
            usdt.address,
            usdc.address,
            amount,
            0,
        );
        const data = ethers.utils.defaultAbiCoder.encode(
            ['uint256[]'],
            [[2, 1]],
        );
        const amountOut = await curveSwapper.getOutputAmount(swapData, data);
        expect(amountOut.gt(0)).to.be.true;
    });
    });
    
    describe('getInputAmount()', () => {
        it('should get input amount', async () => {
        const { curveSwapper, usdt, usdc, createSimpleSwapData } =
            await loadFixture(registerFork);

        const swapData = createSimpleSwapData(usdt.address, usdc.address, 0, 0);
        await expect(curveSwapper.getInputAmount(swapData, '0x')).to.be.reverted;
    });
    });
    
    describe('swap data', () => {
         it('should create swapData throug the contract', async () => {
        const { curveSwapper, binanceWallet, deployer, usdc, usdt } =
            await loadFixture(registerFork);

        const amount = BN(1e6).mul(1000);
        await usdt.connect(binanceWallet).transfer(deployer.address, amount);

        const swapData = await curveSwapper[
            'buildSwapData(address,address,uint256,uint256,bool,bool)'
        ](usdt.address, usdc.address, amount, 0, false, false);
        const data = ethers.utils.defaultAbiCoder.encode(
            ['uint256[]'],
            [[2, 1]],
        );
        await usdt.approve(curveSwapper.address, amount);
        await curveSwapper.swap(swapData, 1, deployer.address, data);
        const usdcBalanceAfter = await usdc.balanceOf(deployer.address);
        expect(usdcBalanceAfter.gt(0)).to.be.true;
    });
    });
   
    describe('swap', () => {
        it('should swap', async () => {
        const {
            curveSwapper,
            usdt,
            usdc,
            binanceWallet,
            deployer,
            createSimpleSwapData,
        } = await loadFixture(registerFork);

        const amount = BN(1e6).mul(1000);
        await usdt.connect(binanceWallet).transfer(deployer.address, amount);

        const usdcBalanceBefore = await usdc.balanceOf(deployer.address);
        expect(usdcBalanceBefore.eq(0)).to.be.true;

        const swapData = createSimpleSwapData(
            usdt.address,
            usdc.address,
            amount,
            0,
        );
        const data = ethers.utils.defaultAbiCoder.encode(
            ['uint256[]'],
            [[2, 1]],
        );
        await usdt.approve(curveSwapper.address, amount);
        await curveSwapper.swap(swapData, 1, deployer.address, data);

        const usdcBalanceAfter = await usdc.balanceOf(deployer.address);
        expect(usdcBalanceAfter.gt(0)).to.be.true;
    });

    it('should swap assets available in YB', async () => {
        const {
            curveSwapper,
            usdt,
            usdc,
            usdtAssetId,
            usdcAssetId,
            binanceWallet,
            deployer,
            yieldBox,
            createYbSwapData,
        } = await loadFixture(registerFork);

        const amount = BN(1e6).mul(1000);
        const share = await yieldBox.toShare(usdtAssetId, amount, false);

        await usdt.connect(binanceWallet).transfer(deployer.address, amount);
        await usdt.approve(yieldBox.address, amount);
        await yieldBox.depositAsset(
            usdtAssetId,
            deployer.address,
            deployer.address,
            0,
            share,
        );

        const ybUsdtBalanceBefore = await yieldBox.balanceOf(
            deployer.address,
            usdtAssetId,
        );
        expect(ybUsdtBalanceBefore.eq(share)).to.be.true;

        const ybUsdcBalanceBefore = await yieldBox.balanceOf(
            deployer.address,
            usdcAssetId,
        );
        expect(ybUsdcBalanceBefore.eq(0)).to.be.true;

        const swapData = await curveSwapper[
            'buildSwapData(uint256,uint256,uint256,uint256,bool,bool)'
        ](usdtAssetId, usdcAssetId, 0, share, true, true);

        const data = ethers.utils.defaultAbiCoder.encode(
            ['uint256[]'],
            [[2, 1]],
        );
        await yieldBox.transfer(
            deployer.address,
            curveSwapper.address,
            usdtAssetId,
            share,
        );
        await curveSwapper.swap(swapData, 1, deployer.address, data);

        const ybUsdtBalanceAfter = await yieldBox.balanceOf(
            deployer.address,
            usdtAssetId,
        );
        expect(ybUsdtBalanceAfter.eq(0)).to.be.true;

        const ybUsdcBalanceAfter = await yieldBox.balanceOf(
            deployer.address,
            usdcAssetId,
        );
        expect(ybUsdcBalanceAfter.gt(0)).to.be.true;
    });
    });
});
