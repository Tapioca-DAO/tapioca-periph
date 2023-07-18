import * as dotenv from 'dotenv';

import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-chai-matchers';
import { HardhatUserConfig } from 'hardhat/config';
import 'hardhat-deploy';
import 'hardhat-contract-sizer';
import '@primitivefi/hardhat-dodoc';
import SDK from 'tapioca-sdk';
import { HttpNetworkConfig } from 'hardhat/types';
import 'hardhat-tracer';
import { TAPIOCA_PROJECTS_NAME } from './gitsub_tapioca-sdk/src/api/config';

dotenv.config();

declare global {
    // eslint-disable-next-line @typescript-eslint/no-namespace
    namespace NodeJS {
        interface ProcessEnv {
            ALCHEMY_API_KEY: string;
        }
    }
}

type TNetwork = ReturnType<
    typeof SDK.API.utils.getSupportedChains
>[number]['name'];
const supportedChains = SDK.API.utils.getSupportedChains().reduce(
    (sdkChains, chain) => ({
        ...sdkChains,
        [chain.name]: <HttpNetworkConfig>{
            accounts:
                process.env.PRIVATE_KEY !== undefined
                    ? [process.env.PRIVATE_KEY]
                    : [],
            live: true,
            url: chain.rpc.replace('<api_key>', process.env.ALCHEMY_API_KEY),
            gasMultiplier: chain.tags[0] === 'testnet' ? 2 : 1,
            chainId: Number(chain.chainId),
            tags: [...chain.tags],
        },
    }),
    {} as { [key in TNetwork]: HttpNetworkConfig },
);
const config: HardhatUserConfig & { dodoc?: any; typechain?: any } = {
    SDK: { project: TAPIOCA_PROJECTS_NAME.TapiocaPeriphery }, //{ project: SDK.API.config.TAPIOCA_PROJECTS_NAME.TapiocaZ },
    solidity: {
        compilers: [
            {
                version: '0.8.18',
                settings: {
                    viaIR: true,
                    optimizer: {
                        enabled: true,
                        runs: 20,
                    },
                },
            },
        ],
    },
    namedAccounts: {
        deployer: 0,
    },
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            saveDeployments: false,
            chainId: 1,
            // chainId: 42161,
            forking: {
                url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
                // url: `https://arb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
                blockNumber: 17068626, // Mainnet
            },
            hardfork: 'merge',
            allowUnlimitedContractSize: true,
            accounts: {
                mnemonic:
                    'test test test test test test test test test test test junk',
                count: 10,
                accountsBalance: '1000000000000000000000',
            },
        },
        ...supportedChains,
    },
    etherscan: {
        apiKey: {
            goerli: process.env.BLOCKSCAN_KEY ?? '',
            arbitrumGoerli: process.env.ARBITRUM_GOERLI_KEY ?? '',
            avalancheFujiTestnet: process.env.AVALANCHE_FUJI_KEY ?? '',
            bscTestnet: process.env.BSC_KEY ?? '',
            polygonMumbai: process.env.POLYGON_MUMBAI ?? '',
            ftmTestnet: process.env.FTM_TESTNET ?? '',
        },
        customChains: [],
    },
    typechain: {
        outDir: './typechain',
    },
    gasReporter: {},
    dodoc: {
        runOnCompile: false,
        freshOutput: true,
    },
    mocha: {
        timeout: 4000000,
    },
};

export default config;
