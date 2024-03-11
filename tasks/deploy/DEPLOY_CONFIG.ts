import { EChainID } from '@tapioca-sdk/api/config';

// Name of the contract deployments to be used in the deployment scripts and saved in the deployments file
export const DEPLOYMENT_NAMES = {
    // Magnetar
    MAGNETAR: 'MAGNETAR',
    MAGNETAR_ASSET_MODULE: 'MAGNETAR_ASSET_MODULE',
    MAGNETAR_ASSET_X_CHAIN_MODULE: 'MAGNETAR_ASSET_X_CHAIN_MODULE',
    MAGNETAR_COLLATERAL_MODULE: 'MAGNETAR_COLLATERAL_MODULE',
    MAGNETAR_MINT_MODULE: 'MAGNETAR_MINT_MODULE',
    MAGNETAR_MINT_X_CHAIN_MODULE: 'MAGNETAR_MINT_X_CHAIN_MODULE',
    MAGNETAR_OPTION_MODULE: 'MAGNETAR_OPTION_MODULE',
    MAGNETAR_YIELDBOX_MODULE: 'MAGNETAR_YIELDBOX_MODULE',
    // Oracles
    DAI_ORACLE: 'DAI_ORACLE',
    ETH_GLP_ORACLE: 'ETH_GLP_ORACLE',
    ETH_ORACLE: 'ETH_ORACLE',
    GLP_ORACLE: 'GLP_ORACLE',
    GMX_ORACLE: 'GMX_ORACLE',
    TAP_ORACLE: 'TAP_ORACLE',
    TAP_OPTION_ORACLE: 'TAP_OPTION_ORACLE',
    // Misc
    PEARLMIT: 'PEARLMIT',
    CLUSTER: 'CLUSTER',
    ZERO_X_SWAPPER: 'ZERO_X_SWAPPER',
};

type TPostLbp = {
    [key in EChainID]?: {
        GMX_USD_CL_DATA_FEED_ADDRESS: string;
        GLP_MANAGER: string;
        WETH_USD_CL_DATA_FEED_ADDRESS: string;
        DAI_USD_CL_DATA_FEED_ADDRESS: string;
    };
};
const POST_LBP: TPostLbp = {
    [EChainID.ARBITRUM]: {
        GMX_USD_CL_DATA_FEED_ADDRESS:
            '0xdb98056fecfff59d032ab628337a4887110df3db',
        GLP_MANAGER: '0x3963FfC9dff443c2A94f21b129D429891E32ec18',
        WETH_USD_CL_DATA_FEED_ADDRESS:
            '0x639fe6ab55c921f74e7fac1ee960c0b6293ba612',
        DAI_USD_CL_DATA_FEED_ADDRESS:
            '0xaed0c38402a5d19df6e4c03f4e2dced6e29c1ee9',
    },
};

POST_LBP['31337' as EChainID] = POST_LBP[EChainID.ARBITRUM]; // Copy from Arbitrum

type TMisc = {
    [key in EChainID]?: {
        CL_SEQUENCER: string;
        WETH_USDC_UNIV3_LP: string;
        WETH: string;
        USDC: string;
        ZERO_X_PROXY: string;
    };
};
const MISC: TMisc = {
    [EChainID.ARBITRUM]: {
        CL_SEQUENCER: '0xFdB631F5EE196F0ed6FAa767959853A9F217697D', // Arbitrum mainnet ChainLink sequencer uptime feed
        WETH_USDC_UNIV3_LP: '0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443', // WETH/USDC LP Arbitrum
        WETH: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
        USDC: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
        ZERO_X_PROXY: '0xdef1c0ded9bec7f1a1670819833240f027b25eff',
    },
    [EChainID.MAINNET]: {
        CL_SEQUENCER: '0x', // Arbitrum mainnet ChainLink sequencer uptime feed
        WETH_USDC_UNIV3_LP: '0x', // WETH/USDC LP
        WETH: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
        USDC: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
        ZERO_X_PROXY: '0xdef1c0ded9bec7f1a1670819833240f027b25eff',
    },
};
MISC['31337' as EChainID] = MISC[EChainID.ARBITRUM]; // Copy from Arbitrum

export const DEPLOY_CONFIG = {
    POST_LBP,
    MISC,
};
