// Plugins
import '@nomicfoundation/hardhat-chai-matchers';
import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-toolbox';
import '@primitivefi/hardhat-dodoc';
import '@typechain/hardhat';
import 'hardhat-contract-sizer';
import 'hardhat-tracer';
import { HardhatUserConfig, subtask } from 'hardhat/config';
import {
    HardhatNetworkUserConfig,
    HttpNetworkConfig,
    HttpNetworkUserConfig,
    NetworksUserConfig,
} from 'hardhat/types';
import { TASK_COMPILE_GET_REMAPPINGS } from 'hardhat/builtin-tasks/task-names';
import fs from 'fs';

// Utils
import { TAPIOCA_PROJECTS_NAME } from '@tapioca-sdk/api/config';
import { SDK, loadEnv } from 'tapioca-sdk';
import 'tapioca-sdk'; // Use directly the un-compiled code, no need to wait for the tarball to be published.

declare global {
    // eslint-disable-next-line @typescript-eslint/no-namespace
    namespace NodeJS {
        interface ProcessEnv {
            ALCHEMY_API_KEY: string;
            ENV: string;
            NETWORK: string; // For forking
        }
    }
}

// Load the env vars from the .env/<network>.env file. the <network> file name is the same as the network in hh `--network arbitrum_sepolia`
loadEnv();
// Check if the folder /gen/typechain exists, if not, create it. This is needed if the repo was freshly cloned.
if (!fs.existsSync('./gen/typechain/index.ts')) {
    try {
        fs.mkdirSync('./gen/typechain', { recursive: true });
    } catch (e) {}
    fs.writeFileSync('./gen/typechain/index.ts', '');
}

// Solves the hardhat error [Error HH415: Two different source names]
subtask(TASK_COMPILE_GET_REMAPPINGS).setAction(async (_, __, runSuper) => {
    // Get the list of source paths that would normally be passed to the Solidity compiler
    const remappings = await runSuper();
    fs.cpSync('contracts/', 'gen/contracts/', { recursive: true });
    remappings['tapioca-periph/'] = 'gen/contracts/';
    return remappings;
});

// TODO refactor all of that in the SDK?
type TNetwork = ReturnType<
    typeof SDK.API.utils.getSupportedChains
>[number]['name'];
const supportedChains = SDK.API.utils.getSupportedChains().reduce(
    (sdkChains, chain) => ({
        ...sdkChains,
        [chain.name]: <HttpNetworkUserConfig>{
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

const config: HardhatUserConfig &
    HardhatNetworkUserConfig & { dodoc?: any; typechain?: any } = {
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
        tests: './test_hardhat',
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
            mining: { auto: true },
            hardfork: 'merge',
            allowUnlimitedContractSize: true,
            accounts: {
                mnemonic:
                    'test test test test test test test test test test test junk',
                count: 10,
                accountsBalance: '1000000000000000000000',
            },
            tags: ['local'],
            ...forkInfo,
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
