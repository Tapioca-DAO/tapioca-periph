import * as dotenv from 'dotenv';

import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-chai-matchers';
import { HardhatUserConfig } from 'hardhat/config';
import 'hardhat-deploy';
import 'hardhat-contract-sizer';
import '@primitivefi/hardhat-dodoc';
import SDK from 'tapioca-sdk';
import { HttpNetworkConfig, NetworksUserConfig } from 'hardhat/types';
import 'hardhat-tracer';

dotenv.config();

declare global {
    // eslint-disable-next-line @typescript-eslint/no-namespace
    namespace NodeJS {
        interface ProcessEnv {
            ALCHEMY_API_KEY: string;
            NETWORK: string;
            FROM_BLOCK: string;
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
    SDK: { project: SDK.API.config.TAPIOCA_PROJECTS_NAME.TapiocaPeriphery },
    solidity: {
        compilers: [
            {
                version: '0.8.19',
                settings: {
                    viaIR: true,
                    optimizer: {
                        enabled: true,
                        runs: 5,
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
        freshOutput: false,
    },
    mocha: {
        timeout: 4000000,
    },
};

export default config;
