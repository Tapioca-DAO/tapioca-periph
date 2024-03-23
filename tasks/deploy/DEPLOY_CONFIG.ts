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
    MAGNETAR_BASE_MODULE_EXTERNAL: 'MAGNETAR_BASE_MODULE_EXTERNAL',
    // Oracles
    DAI_ORACLE: 'DAI_ORACLE',
    ETH_GLP_ORACLE: 'ETH_GLP_ORACLE',
    ETH_ORACLE: 'ETH_ORACLE',
    GLP_ORACLE: 'GLP_ORACLE',
    GMX_ORACLE: 'GMX_ORACLE',
    TAP_ORACLE: 'TAP_ORACLE',
    ADB_TAP_OPTION_ORACLE: 'ADB_TAP_OPTION_ORACLE',
    TOB_TAP_OPTION_ORACLE: 'TOB_TAP_OPTION_ORACLE',
    // Misc
    PEARLMIT: 'PEARLMIT',
    CLUSTER: 'CLUSTER',
    ZERO_X_SWAPPER: 'ZERO_X_SWAPPER',
    TAP_WETH_UNI_V3_POOL: 'TAP_WETH_UNI_V3_POOL',
} as const;

type TPostLbp = {
    [key in EChainID]?: {
        GMX_USD_CL_DATA_FEED_ADDRESS: string;
        GLP_MANAGER: string;
        WETH_USD_CL_DATA_FEED_ADDRESS: string;
        DAI_USD_CL_DATA_FEED_ADDRESS: string;
        USDC_USD_CL_DATA_FEED_ADDRESS: string;
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
        USDC_USD_CL_DATA_FEED_ADDRESS:
            '0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3',
    },
    [EChainID.ARBITRUM_SEPOLIA]: {
        GMX_USD_CL_DATA_FEED_ADDRESS:
            '0xb09a4dE01be905e7C1f2d0d95eaDe2877110eDbF',
        GLP_MANAGER: '0x9Dd145b3C100498eE3BFF45E53cEB93cDe0075b4', // Locally deployed GLPManager Mock
        WETH_USD_CL_DATA_FEED_ADDRESS:
            '0x1444F15C73FdCDA08B72592af855776Be88B45d4', // Locally deployed WETH/USD Chainlink Mock
        DAI_USD_CL_DATA_FEED_ADDRESS:
            '0x4cAfe3Df6Ae3E4ecbA6fD9663b494E10c5B648E5', // Locally deployed DAI/USD Chainlink Mock
        USDC_USD_CL_DATA_FEED_ADDRESS:
            '0xC23507096A67D62d511CBE9D9f335dbef8F5De27', // Locally deployed USDC/USD Chainlink Mock
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
        NONFUNGIBLE_POSITION_MANAGER: string;
        V3_SWAP_ROUTER: string;
        V3_FACTORY: string;
        ARRAKIS_FACTORY: string;
        ARRAKIS_RESOLVER: string;
    };
};

const MISC: TMisc = {
    // Mainnet
    [EChainID.ARBITRUM]: {
        CL_SEQUENCER: '0xFdB631F5EE196F0ed6FAa767959853A9F217697D', // Arbitrum mainnet ChainLink sequencer uptime feed
        WETH_USDC_UNIV3_LP: '0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443', // WETH/USDC LP Arbitrum
        WETH: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
        USDC: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
        ZERO_X_PROXY: '0xdef1c0ded9bec7f1a1670819833240f027b25eff',
        NONFUNGIBLE_POSITION_MANAGER:
            '0xc36442b4a4522e871399cd717abdd847ab11fe88',
        V3_FACTORY: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
        V3_SWAP_ROUTER: '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45',
        ARRAKIS_FACTORY: '0xECb8Ffcb2369EF188A082a662F496126f66c8288',
        ARRAKIS_RESOLVER: '0x535C5fDf31477f799366DF6E4899a12A801cC7b8',
    },
    [EChainID.MAINNET]: {
        CL_SEQUENCER: '0x', // Arbitrum mainnet ChainLink sequencer uptime feed
        WETH_USDC_UNIV3_LP: '0x', // WETH/USDC LP
        WETH: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
        USDC: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
        ZERO_X_PROXY: '0xdef1c0ded9bec7f1a1670819833240f027b25eff',
        NONFUNGIBLE_POSITION_MANAGER:
            '0xc36442b4a4522e871399cd717abdd847ab11fe88',
        V3_FACTORY: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
        V3_SWAP_ROUTER: '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45',
        ARRAKIS_FACTORY: '', // Empty means not needed/intended for this chain
        ARRAKIS_RESOLVER: '', // Empty means not needed/intended for this chain
    },
    // Testnet
    [EChainID.ARBITRUM_SEPOLIA]: {
        CL_SEQUENCER: '0x0000000000000000000000000000000000000000',
        WETH_USDC_UNIV3_LP: '0x82E16a9D4477CB2318788b86f0B66Ed3223349a8', // Locally deployed WETH/USDC LP | USDCMock/WETH9 with - fee 3000 - ratio 1/2000
        WETH: '0x997FE31Adda5c969691768Ad1140273290952333', // Locally deployed WETH9 Mock
        USDC: '0x6D6a13AbE7935b2cf6d67e49bc17F5035362C705', // Locally deployed USDC Mock
        ZERO_X_PROXY: '0x',
        NONFUNGIBLE_POSITION_MANAGER:
            '0xFd1a7CA61e49703da3618999B2EEdc0E79476759',
        V3_FACTORY: '0x76D8F1D83716bcd0f811449a76Fc2B3E3ef98454',
        V3_SWAP_ROUTER: '0x20C5707e71872463c3063247636fbcE434076597',
        ARRAKIS_FACTORY: '0x1c90088A93e9c7844aE0f0a6A7573891342BFe93',
        ARRAKIS_RESOLVER: '0xD0D11a8fFD49a4b0B90936dc97814DBbA6C8Dd78',
    },
    [EChainID.OPTIMISM_SEPOLIA]: {
        CL_SEQUENCER: '0x0000000000000000000000000000000000000000',
        WETH_USDC_UNIV3_LP: '0x', // Locally deployed WETH/USDC LP | USDCMock/WETH9 with - fee 3000 - ratio 1/2000
        WETH: '0x4fB538Ed1a085200bD08F66083B72c0bfEb29112', // Locally deployed WETH9 Mock
        USDC: '0xEa0C9CAef2A40Ea196473b3DE6e52Ca106BEeB2A', // Locally deployed USDC Mock
        ZERO_X_PROXY: '0x',
        NONFUNGIBLE_POSITION_MANAGER:
            '0x568DFf712af02F07A0b9dBEb6b019a9e11adC6Bd',
        V3_FACTORY: '0xd93F65e5Ee424891dBCDEAFE347a553C43d266b7',
        V3_SWAP_ROUTER: '', // Empty means not needed/intended for this chain
        ARRAKIS_FACTORY: '', // Empty means not needed/intended for this chain
        ARRAKIS_RESOLVER: '', // Empty means not needed/intended for this chain
    },
};
MISC['31337' as EChainID] = MISC[EChainID.ARBITRUM]; // Copy from Arbitrum

export const DEPLOY_CONFIG = {
    POST_LBP,
    MISC,
};
