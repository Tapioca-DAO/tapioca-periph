import * as dotenv from 'dotenv';

import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-chai-matchers';
import { HardhatUserConfig } from 'hardhat/config';
import 'hardhat-deploy';
import 'hardhat-contract-sizer';
import '@primitivefi/hardhat-dodoc';
import { HttpNetworkConfig, NetworksUserConfig } from 'hardhat/types';
import 'hardhat-tracer';

// Tapioca
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { SDK, loadEnv } from 'tapioca-sdk';
import 'tapioca-sdk'; // Use directly the un-compiled code, no need to wait for the tarball to be published.

dotenv.config();

declare global {
    // eslint-disable-next-line @typescript-eslint/no-namespace
    namespace NodeJS {
        interface ProcessEnv {
            ALCHEMY_API_KEY: string;
            NETWORK: string;
            FROM_BLOCK: string;
            BINANCE_WALLET_ADDRESS: string;
        }
    }
}

loadEnv();

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

const forkNetwork = process.env.NETWORK as TNetwork;
const forkChainInfo = supportedChains[forkNetwork];
const forkInfo: NetworksUserConfig['hardhat'] = forkNetwork
    ? {
          chainId: forkChainInfo.chainId,
          forking: {
              url: forkChainInfo.url,
              ...(process.env.FROM_BLOCK
                  ? { blockNumber: Number(process.env.FROM_BLOCK) }
                  : {}),
          },
      }
    : {};

const config: HardhatUserConfig & { dodoc?: any; typechain?: any } = {
    SDK: { project: TAPIOCA_PROJECTS_NAME.TapiocaPeriphery },
    solidity: {
        compilers: [
            {
                version: '0.8.22',
                settings: {
                    evmVersion: 'paris', // Latest before Shanghai
                    optimizer: {
                        enabled: true,
                        runs: 9999,
                    },
                },
            },
        ],
    },
    paths: {
        artifacts: './gen/artifacts',
        cache: './gen/cache',
    },
    dodoc: {
        runOnCompile: false,
        freshOutput: false,
        outputDir: 'gen/docs',
    },
    typechain: {
        outDir: 'gen/typechain',
        target: 'ethers-v5',
    },
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
            accounts: {
                count: 5,
            },
        },
        ...supportedChains,
    },
    etherscan: {
        apiKey: {
            sepolia: process.env.SCAN_API_KEY ?? '',
            arbitrumSepolia: process.env.SCAN_API_KEY ?? '',
            optimismSepolia: process.env.SCAN_API_KEY ?? '',
            avalancheFujiTestnet: process.env.SCAN_API_KEY ?? '',
            bscTestnet: process.env.SCAN_API_KEY ?? '',
            polygonMumbai: process.env.SCAN_API_KEY ?? '',
            ftmTestnet: process.env.SCAN_API_KEY ?? '',
        },
        customChains: [
            {
                network: 'arbitrumSepolia',
                chainId: 421614,
                urls: {
                    apiURL: 'https://api-sepolia.arbiscan.io/api',
                    browserURL: 'https://sepolia.arbiscan.io/',
                },
            },
            {
                network: 'optimismSepolia',
                chainId: 11155420,
                urls: {
                    apiURL: 'https://api-sepolia-optimistic.etherscan.io/',
                    browserURL: 'https://sepolia-optimism.etherscan.io/',
                },
            },
        ],
    },
};

export default config;
