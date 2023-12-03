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

export const ARGS_CONFIG = {
    [EChainID.ARBITRUM]: {
        ...TAP_ORACLE[EChainID.ARBITRUM],
        ...GLP_ORACLE[EChainID.ARBITRUM],
        ...GMX_ORACLE[EChainID.ARBITRUM],
        ...MISC[EChainID.ARBITRUM],
    },
    [EChainID.MAINNET]: {
        ...DAI_ORACLE[EChainID.MAINNET],
    },
};
