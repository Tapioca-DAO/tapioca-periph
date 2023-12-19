import { EChainID } from '../../gitsub_tapioca-sdk/src/api/config';

const TAP_ORACLE = {
    [EChainID.ARBITRUM]: {
        TAP_ORACLE: {
            TAP_ADDRESS: '0x0',
            TAP_USDC_LP_ADDRESS: '0x0',
        },
    },
};

const GLP_ORACLE = {
    [EChainID.ARBITRUM]: {
        GLP_ORACLE: {
            GLP_MANAGER: '0x3963FfC9dff443c2A94f21b129D429891E32ec18', // GLP Manager
        },
    },
};

const ETH_ORACLE = {
    [EChainID.ARBITRUM]: {
        WETH_ORACLE: {
            WETH_ADDRESS: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
            WETH_USD_CL_DATA_FEED_ADDRESS:
                '0x639fe6ab55c921f74e7fac1ee960c0b6293ba612',
        },
    },
};

const DAI_ORACLE = {
    [EChainID.MAINNET]: {
        DAI_ORACLE: {
            DAI_ADDRESS: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
            DAI_USD_CL_DATA_FEED_ADDRESS:
                '0xaed0c38402a5d19df6e4c03f4e2dced6e29c1ee9',
        },
    },
};

const GMX_ORACLE = {
    [EChainID.ARBITRUM]: {
        GMX_ORACLE: {
            GMX_ADDRESS: '0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a',
            GMX_USD_CL_DATA_FEED_ADDRESS:
                '0xdb98056fecfff59d032ab628337a4887110df3db',
        },
    },
};

const MISC = {
    [EChainID.ARBITRUM]: {
        MISC: {
            CL_SEQUENCER: '0xFdB631F5EE196F0ed6FAa767959853A9F217697D', // Arbitrum mainnet ChainLink sequencer uptime feed
            USDC_ADDRESS: '0xFdB631F5EE196F0ed6FAa767959853A9F217697D', // USDC address on Arbitrum
        },
    },
};

const SWAPPERS_CONFIG = {
    [EChainID.ARBITRUM]: {
        UNISWAPV2_ROUTER: '',
        UNISWAPV2_FACTORY: '',
        UNISWAPV3_ROUTER: '',
        UNISWAPV3_FACTORY: '',
    },
    [EChainID.MAINNET]: {
        UNISWAPV2_ROUTER: '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
        UNISWAPV2_FACTORY: '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f',
        UNISWAPV3_ROUTER: '0xE592427A0AEce92De3Edee1F18E0157C05861564',
        UNISWAPV3_FACTORY: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
    },
    [EChainID.AVALANCHE]: {
        UNISWAPV2_ROUTER: '',
        UNISWAPV2_FACTORY: '',
        UNISWAPV3_ROUTER: '',
        UNISWAPV3_FACTORY: '',
    },
    [EChainID.FANTOM]: {
        UNISWAPV2_ROUTER: '',
        UNISWAPV2_FACTORY: '',
        UNISWAPV3_ROUTER: '',
        UNISWAPV3_FACTORY: '',
    },
    [EChainID.POLYGON]: {
        UNISWAPV2_ROUTER: '',
        UNISWAPV2_FACTORY: '',
        UNISWAPV3_ROUTER: '',
        UNISWAPV3_FACTORY: '',
    },

    //TESTNETS
    [EChainID.ARBITRUM_GOERLI]: {
        UNISWAPV2_ROUTER: '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
        UNISWAPV2_FACTORY: '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f',
        UNISWAPV3_ROUTER: '0xE592427A0AEce92De3Edee1F18E0157C05861564',
        UNISWAPV3_FACTORY: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
    },
};

export const ARGS_CONFIG = {
    [EChainID.ARBITRUM]: {
        ...TAP_ORACLE[EChainID.ARBITRUM],
        ...GLP_ORACLE[EChainID.ARBITRUM],
        ...GMX_ORACLE[EChainID.ARBITRUM],
        ...ETH_ORACLE[EChainID.ARBITRUM],
        ...MISC[EChainID.ARBITRUM],
        ...SWAPPERS_CONFIG[EChainID.ARBITRUM],
    },
    [EChainID.MAINNET]: {
        ...DAI_ORACLE[EChainID.MAINNET],
        ...SWAPPERS_CONFIG[EChainID.MAINNET],
    },
    [EChainID.AVALANCHE]: {
        ...SWAPPERS_CONFIG[EChainID.AVALANCHE],
    },
    [EChainID.FANTOM]: {
        ...SWAPPERS_CONFIG[EChainID.FANTOM],
    },
    [EChainID.POLYGON]: {
        ...SWAPPERS_CONFIG[EChainID.POLYGON],
    },

    //TESTNETS
    [EChainID.ARBITRUM_GOERLI]: {
        ...SWAPPERS_CONFIG[EChainID.ARBITRUM_GOERLI],
    },
};
