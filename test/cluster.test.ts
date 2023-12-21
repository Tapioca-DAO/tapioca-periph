import hre, { ethers } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { BN, register, registerFork } from './test.utils';

describe('Cluster', () => {
    before(function () {
        if (process.env.NETWORK != 'ethereum') {
            console.log('[!] Cluster tests are only for ethereum fork');
            this.skip();
        }
    });
    describe('editors', () => {
        it('should update editors', async () => {
            const { cluster, eoa1 } = await loadFixture(register);

            const randomWallet = ethers.Wallet.createRandom();
            let isEditor = await cluster.isEditor(randomWallet.address);
            expect(isEditor).to.be.false;

            await expect(
                cluster.connect(eoa1).updateEditor(randomWallet.address, true),
            ).to.be.reverted;

            await cluster.updateEditor(randomWallet.address, true);
            isEditor = await cluster.isEditor(randomWallet.address);
            expect(isEditor).to.be.true;

            await cluster.updateEditor(randomWallet.address, false);
            isEditor = await cluster.isEditor(randomWallet.address);
            expect(isEditor).to.be.false;
        });
    });
    describe('LZ chain', () => {
        it('should update LZ chain id', async () => {
            const { cluster, eoa1 } = await loadFixture(register);

            let lzChainId = await cluster.lzChainId();
            expect(lzChainId).to.eq(31337);

            await expect(cluster.connect(eoa1).updateLzChain(2)).to.be.reverted;

            await cluster.updateLzChain(2);
            lzChainId = await cluster.lzChainId();
            expect(lzChainId).to.eq(2);
        });
    });

    describe('whitelist', () => {
        it('should whitelist contract without specifying the lz chain id', async () => {
            const { cluster, eoa1 } = await loadFixture(register);

            const randomContract = ethers.Wallet.createRandom();
            let isWhitelisted = await cluster.isWhitelisted(
                1,
                randomContract.address,
            );
            expect(isWhitelisted).to.be.false;

            await expect(
                cluster
                    .connect(eoa1)
                    .updateContract(0, randomContract.address, true),
            ).to.be.reverted;

            await cluster.updateEditor(eoa1.address, true);
            await expect(
                cluster
                    .connect(eoa1)
                    .updateContract(0, randomContract.address, true),
            ).to.not.be.reverted;

            isWhitelisted = await cluster.isWhitelisted(
                0,
                randomContract.address,
            );
            expect(isWhitelisted).to.be.true;
        });

        it('should whitelist contract for specific lz chain id', async () => {
            const { cluster, eoa1 } = await loadFixture(register);

            const randomContract = ethers.Wallet.createRandom();
            let isWhitelisted = await cluster.isWhitelisted(
                1,
                randomContract.address,
            );
            expect(isWhitelisted).to.be.false;

            await expect(
                cluster
                    .connect(eoa1)
                    .updateContract(2, randomContract.address, true),
            ).to.be.reverted;

            await cluster.updateEditor(eoa1.address, true);
            await expect(
                cluster
                    .connect(eoa1)
                    .updateContract(2, randomContract.address, true),
            ).to.not.be.reverted;

            isWhitelisted = await cluster.isWhitelisted(
                2,
                randomContract.address,
            );
            expect(isWhitelisted).to.be.true;

            isWhitelisted = await cluster.isWhitelisted(
                1,
                randomContract.address,
            );
            expect(isWhitelisted).to.be.false;
        });
    });
});
