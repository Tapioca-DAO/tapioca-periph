import { time } from '@nomicfoundation/hardhat-network-helpers';
import { BigNumberish } from 'ethers';
import { ethers } from 'hardhat';

ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR);
const verifyEtherscanQueue: { address: string; args: any[] }[] = [];

async function resetVM() {
    await ethers.provider.send('hardhat_reset', []);
}

export function BN(n: BigNumberish) {
    return ethers.BigNumber.from(n.toString());
}

export async function setBalance(addr: string, ether: number) {
    await ethers.provider.send('hardhat_setBalance', [
        addr,
        ethers.utils.hexStripZeros(ethers.utils.parseEther(String(ether))._hex),
    ]);
}

const log = (message: string, staging?: boolean) =>
    staging && console.log(message);
export async function register(staging?: boolean) {
    if (!staging) {
        await resetVM();
    }

    const deployer = (await ethers.getSigners())[0];
    const eoas = await ethers.getSigners();
    eoas.shift(); //remove deployer

    const eoa1 = new ethers.Wallet(
        ethers.Wallet.createRandom().privateKey,
        ethers.provider,
    );

    if (!staging) {
        await setBalance(eoa1.address, 100000);
    }

    const initialSetup = {
        deployer,
        eoas,
        eoa1,
    };

    const timeTravel = async (seconds: number) => {
        await time.increase(seconds);
    };

    const utilFuncs = {
        BN,
        timeTravel,
    };

    return { ...initialSetup, ...utilFuncs, verifyEtherscanQueue };
}
