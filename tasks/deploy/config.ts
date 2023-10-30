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
        ...MISC[EChainID.ARBITRUM],
    },
};
