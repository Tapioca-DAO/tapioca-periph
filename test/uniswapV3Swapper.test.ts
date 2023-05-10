import hre, { ethers } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { BN, registerFork } from './test.utils';

describe('UniswapV3Swapper', () => {
    describe('getOutputAmount()', () => {
         it('should get output amount', async () => {
            const { uniswapV3Swapper, weth, usdc, createSimpleSwapData } =
                await loadFixture(registerFork);
            const amount = BN(1e18);

            const swapData = createSimpleSwapData(
                weth.address,
                usdc.address,
                amount,
                0,
            );
            const amountOut = await uniswapV3Swapper.getOutputAmount(
                swapData,
                '0x00',
            );
            expect(amountOut.gt(0)).to.be.true;
        });
    });
   
    describe('getInputAmount()', () => {
        it('should get input amount', async () => {
        const { uniswapV3Swapper, weth, usdc, createSimpleSwapData } = await loadFixture(registerFork);
        const amount = BN(1e6).mul(1000);

        const swapData = createSimpleSwapData(
            weth.address,
            usdc.address,
            0,
            amount,
        );
        const amountIn = await uniswapV3Swapper.getInputAmount(
            swapData,
            '0x00',
        );

        expect(amountIn.gt(0)).to.be.true;
    });
    });
    
    describe('swap()', () => {
        it('should swap', async () => {
            const {
                uniswapV3Swapper,
                deployer,
                binanceWallet,
                weth,
                usdc,
                createSimpleSwapData,
            } = await loadFixture(registerFork);
            const amount = BN(1e18);

            await weth.connect(binanceWallet).transfer(deployer.address, amount);
            const usdcBalanceBefore = await usdc.balanceOf(deployer.address);
            expect(usdcBalanceBefore.eq(0)).to.be.true;

            const swapData = createSimpleSwapData(
                weth.address,
                usdc.address,
                amount,
                0,
            );
            await weth.approve(uniswapV3Swapper.address, amount);
            await uniswapV3Swapper.swap(swapData, 0, deployer.address, '0x');

            const usdcBalanceAfter = await usdc.balanceOf(deployer.address);
            expect(usdcBalanceAfter.gt(0)).to.be.true;
        });

        it('should swap assets available in YB', async () => {
            const {
                uniswapV3Swapper,
                yieldBox,
                deployer,
                binanceWallet,
                weth,
                usdc,
                wethAssetId,
                usdcAssetId,
                createYbSwapData,
            } = await loadFixture(registerFork);

            const amount = BN(1e18);
            const share = await yieldBox.toShare(wethAssetId, amount, false);

            await weth.connect(binanceWallet).transfer(deployer.address, amount);
            await weth.approve(yieldBox.address, amount);
            await yieldBox.depositAsset(
                wethAssetId,
                deployer.address,
                deployer.address,
                0,
                share,
            );

            const ybWethBalanceBefore = await yieldBox.balanceOf(
                deployer.address,
                wethAssetId,
            );
            expect(ybWethBalanceBefore.eq(share)).to.be.true;

            const ybUsdcBalanceBefore = await yieldBox.balanceOf(
                deployer.address,
                usdcAssetId,
            );
            expect(ybUsdcBalanceBefore.eq(0)).to.be.true;

            const swapData = createYbSwapData(wethAssetId, usdcAssetId, share, 0);
            await yieldBox.transfer(
                deployer.address,
                uniswapV3Swapper.address,
                wethAssetId,
                share,
            );
            await uniswapV3Swapper.swap(swapData, 0, deployer.address, '0x');

            const ybWethBalanceAfter = await yieldBox.balanceOf(
                deployer.address,
                wethAssetId,
            );
            expect(ybWethBalanceAfter.eq(0)).to.be.true;

            const ybUsdcBalanceAfter = await yieldBox.balanceOf(
                deployer.address,
                usdcAssetId,
            );
            expect(ybUsdcBalanceAfter.gt(0)).to.be.true;
        });
    });
});
