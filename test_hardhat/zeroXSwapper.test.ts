import { impersonateAccount } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import * as dotenv from 'dotenv';
import { ethers } from 'hardhat';
import { WETH9Mock__factory } from '@tapioca-sdk/typechain/YieldBox';
import { IERC20__factory } from '@typechain/index';

enum OrderType {
    Bridge = 0,
    Limit = 1,
    Rfq = 2,
    Otc = 3,
}

interface Fees {
    // Define properties of fees based on your requirements
    zeroExFee: ZeroExFee;
}

interface ZeroExFee {
    // Type of the fee.
    feeType: string;
    // The ERC20 token address used for the fee.
    feeToken: string;
    // The amount of feeToken to be charged as the 0x fee.
    feeAmount: string;
    // The method of transferring the 0x fee.
    billingType: string;
}

declare global {
    // eslint-disable-next-line @typescript-eslint/no-namespace
    namespace NodeJS {
        interface ProcessEnv {
            zeroXKey: string;
        }
    }
}

describe.only('ZeroXSwapper-fork test on mainnet', () => {
    before(function () {
        if (process.env.NETWORK != 'ethereum') {
            console.log(
                '[!] ZeroXSwapper-fork tests are only for ethereum fork',
            );
            this.skip();
        }
        dotenv.config();
        if (!process.env.zeroXKey) {
            throw new Error('missing zeroXKey in .env');
        }
        if (!process.env.BINANCE_WALLET_ADDRESS) {
            throw new Error('missing BINANCE_WALLET_ADDRESS in .env');
        }
    });

    it('should swap WETH to DAI', async () => {
        await impersonateAccount(process.env.BINANCE_WALLET_ADDRESS);
        // eslint-disable-next-line prefer-const
        const binanceWallet = await ethers.getSigner(
            process.env.BINANCE_WALLET_ADDRESS,
        );

        const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; // mainnet weth
        const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'; // mainnet dai

        const zeroXApiUrl = 'https://api.0x.org/swap/v1/quote';
        const headers = { '0x-api-key': process.env.zeroXKey };

        const sellAmount = ethers.utils.parseEther('100');
        const query = objToQuery({
            sellToken: WETH,
            buyToken: DAI,
            sellAmount: sellAmount.toString(),
        } as ZeroXQueryParams);

        const quoteUrl = `${zeroXApiUrl}?${query}`;
        const response = await fetch(quoteUrl, { headers });
        const quote: ZeroXResponse = await response.json();

        const owner = (await ethers.getSigners())[0];
        const cluster = await (
            await ethers.getContractFactory('Cluster')
        ).deploy(0, owner.address);
        const zeroXSwapper = await (
            await ethers.getContractFactory('ZeroXSwapper')
        ).deploy(
            '0xdef1c0ded9bec7f1a1670819833240f027b25eff',
            ethers.constants.AddressZero, // 0x for 1inch for now
            cluster.address,
            owner.address,
        );
        await cluster.updateContract(0, binanceWallet.address, true);

        const weth = WETH9Mock__factory.connect(WETH, binanceWallet);
        const dai = IERC20__factory.connect(DAI, binanceWallet);

        await weth.deposit({ value: sellAmount });
        await weth
            .connect(binanceWallet)
            .approve(zeroXSwapper.address, sellAmount);

        const balDaiBefore = await dai.balanceOf(binanceWallet.address);
        await zeroXSwapper.connect(binanceWallet).swap(
            {
                buyToken: quote.buyTokenAddress,
                sellToken: quote.sellTokenAddress,
                swapCallData: quote.data,
                swapTarget: quote.to,
            },
            sellAmount,
            0,
        );
        const balDaiAfter = await dai.balanceOf(binanceWallet.address);

        const spread = ethers.utils
            .parseEther(quote.buyAmount)
            .mul(1)
            .div(1000); // 0.1% spread
        expect(balDaiAfter.sub(balDaiBefore)).to.be.approximately(
            quote.buyAmount,
            spread,
        );
    });
});

function objToQuery(object: { [key: string]: any }): string {
    return Object.keys(object)
        .map((key) => `${key}=${object[key]}`)
        .join('&');
}

interface ZeroXQueryParams {
    sellToken: string;
    buyToken: string;
    sellAmount: string;
}

interface ZeroXResponse {
    // The price of buyToken in sellToken and vice versa. Includes fees if applicable.
    price: string;
    // Price with fees removed, representing the price without any fee charged.
    grossPrice: string;
    // The minimum price that must be met for the transaction to succeed.
    guaranteedPrice: string;
    // Estimated change in price due to the swap. Null if the change can't be estimated.
    estimatedPriceImpact: string | null;
    // The address of the contract to send call data to.
    to: string;
    // The call data required to be sent to the contract address.
    data: string;
    // The amount of ether (in wei) to be sent with the transaction.
    value: string;
    // The gas price (in wei) to be used for sending the transaction.
    gasPrice: string;
    // The estimated gas limit for the transaction.
    gas: string;
    // The estimate of the actual gas to be used in the transaction.
    estimatedGas: string;
    // The maximum ether amount (in wei) for the protocol fee.
    protocolFee: string;
    // The minimum ether amount (in wei) for the protocol fee during the transaction.
    minimumProtocolFee: string;
    // The amount of buyToken to be bought in this swap.
    buyAmount: string;
    // Buy amount with fees removed.
    grossBuyAmount: string;
    // The amount of sellToken to be sold in this swap.
    sellAmount: string;
    // Sell amount with fees removed.
    grossSellAmount: string;
    // Distribution of buy/sell amount between each liquidity source.
    sources: Array<LiquiditySource>;
    // The ERC20 token address of the buy token.
    buyTokenAddress: string;
    // The ERC20 token address of the sell token.
    sellTokenAddress: string;
    // The target contract address for allowance checking.
    allowanceTarget: string;
    // Details of orders used by market makers.
    // orders: Array<Order>;
    // Type of the order as defined in the 0x Protocol.
    type: OrderType;
    // The rate between ETH and sellToken.
    sellTokenToEthRate: string;
    // The rate between ETH and buyToken.
    buyTokenToEthRate: string;
    // Expected slippage used in routing calculations.
    expectedSlippage: string | null;
    // 0x Swap API fees that would be charged.
    fees: Fees;
    // Details of the 0x fee.
    zeroExFee: ZeroExFee;
}

interface LiquiditySource {
    // Name of the liquidity source.
    name: string;

    // Proportion of the total amount provided by this source.
    proportion: string;
}
