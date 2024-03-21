import { HardhatRuntimeEnvironment } from 'hardhat/types';
import BigNumberJS from 'bignumber.js';

export const uniPoolInfo__task = async (
    _taskArgs: { poolAddr: string },
    hre: HardhatRuntimeEnvironment,
) => {
    const { poolAddr } = _taskArgs;

    const uniPool = await hre.ethers.getContractAt('IUniswapV3Pool', poolAddr);
    const token0 = await hre.ethers.getContractAt(
        'ERC20Mock',
        await uniPool.token0(),
    );
    const token1 = await hre.ethers.getContractAt(
        'ERC20Mock',
        await uniPool.token1(),
    );

    console.log(
        '[+] Uniswap pool:',
        await token0.name(),
        '/',
        await token1.name(),
    );
    console.log('[+] liquidity:', await uniPool.liquidity());
    const sqrtPriceX96 = (await uniPool.slot0()).sqrtPriceX96;
    const price = BigNumberJS(sqrtPriceX96.toString())
        .pow(2)
        .div(2 ** 192)
        .toString();

    console.log('[+] Current price:', price.toString());
};
