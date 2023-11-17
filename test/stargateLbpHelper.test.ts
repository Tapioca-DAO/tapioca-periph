import hre, { ethers } from 'hardhat';
import { expect } from 'chai';
import { register, impersonateAccount } from './test.utils';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import _ from 'lodash';
import { BalancerPoolMock__factory } from '../gitsub_tapioca-sdk/src/typechain/tapioca-strategies';
import { BalancerVaultMock__factory } from '../gitsub_tapioca-sdk/src/typechain/tapioca-mocks';

//this won't work due to the local setup,
describe.skip('StargateLbpHelper-fork test', () => {
    before(function () {
        if (process.env.NODE_ENV != 'mainnet') {
            this.skip();
        }
    });

    async function setUpFork() {
        const { deployer } = await loadFixture(register);

        const usdcAddress = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
        const realUsdcContract = await ethers.getContractAt(
            '@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20',
            usdcAddress,
        );

        const targetUsdcAddress = '0xaf88d065e77c8cC2239327C5EDb3A432268e5831';

        const stargateRouterAddress =
            '0x8731d54e9d02c286767d56ac03e8037c07e01e98';
        const realStargateRouterContract = await ethers.getContractAt(
            'IStargateRouter',
            stargateRouterAddress,
        );

        const binanceWallet = '0x28C6c06298d514Db089934071355E5743bf21d60';
        await impersonateAccount(binanceWallet);
        const binanceAccount = await ethers.getSigner(binanceWallet);

        const BalancerVaultMock = new BalancerVaultMock__factory(deployer);
        const lbpDestination = await BalancerVaultMock.deploy();

        const factory = await ethers.getContractFactory('StargateLbpHelper');
        const lbpHelperSource = await factory.deploy(
            stargateRouterAddress,
            ethers.constants.AddressZero,
            ethers.constants.AddressZero,
        );
        const lbpHelperDestination = await factory.deploy(
            stargateRouterAddress,
            lbpDestination.address,
            lbpDestination.address,
        );

        const ethStargateUsdcPoolId = 1;
        const arbStargateUsdcPoolId = 1;
        const dstStargateChainId = 110; //arb

        return {
            targetUsdcAddress,
            realUsdcContract,
            deployer,
            binanceAccount,
            lbpDestination,
            realStargateRouterContract,
            lbpHelperSource,
            lbpHelperDestination,
            ethStargateUsdcPoolId,
            arbStargateUsdcPoolId,
            dstStargateChainId,
        };
    }

    it('should use Stargate to transfer USDC to arbitrum', async () => {
        const {
            realUsdcContract,
            deployer,
            binanceAccount,
            lbpDestination,
            realStargateRouterContract,
            lbpHelperSource,
            lbpHelperDestination,
            targetUsdcAddress,
            ethStargateUsdcPoolId,
            arbStargateUsdcPoolId,
            dstStargateChainId,
        } = await loadFixture(setUpFork);

        const amountUsdc = '100000000'; //100

        await realUsdcContract
            .connect(binanceAccount)
            .transfer(deployer.address, amountUsdc);

        await realUsdcContract.approve(lbpHelperSource.address, amountUsdc);
        await lbpHelperSource.participate(
            {
                srcToken: realUsdcContract.address,
                targetToken: targetUsdcAddress, //arbitrum usdc
                dstChainId: dstStargateChainId,
                peer: lbpHelperDestination.address,
                amount: amountUsdc,
                slippage: (1e4).toString(),
                srcPoolId: ethStargateUsdcPoolId, //eth usdc pool id
                dstPoolId: arbStargateUsdcPoolId, //arb usdc pool id
            },
            {
                assetIn: targetUsdcAddress,
                assetOut: ethers.constants.AddressZero, // it should be TAP address in a real situation
                poolId: 0, //it should be the LBP pool address in a real situation
                deadline: '9999999',
            },
            {
                value: ethers.utils.parseEther('2'),
            },
        );
    });
});
