import { EChainID } from '@tapioca-sdk/api/config';

// Name of the contract deployments to be used in the deployment scripts and saved in the deployments file
export const DEPLOYMENT_NAMES = {
    // TO MOVE
    PEARLMIT: 'PEARLMIT',
    CLUSTER: 'CLUSTER',
};

type TPostLbp = {
    [key in EChainID]?: {};
};

const POST_LBP: TPostLbp = {
    [EChainID.ARBITRUM]: {},
};
POST_LBP[EChainID.ARBITRUM_SEPOLIA] = POST_LBP[EChainID.ARBITRUM]; // Copy from Arbitrum
POST_LBP[EChainID.SEPOLIA] = POST_LBP[EChainID.ARBITRUM]; // Copy from Arbitrum
POST_LBP['31337' as EChainID] = POST_LBP[EChainID.ARBITRUM]; // Copy from Arbitrum

type TFinal = {
    [key in EChainID]?: {};
};

const FINAL: TFinal = {
    [EChainID.ARBITRUM]: {},
};
FINAL[EChainID.ARBITRUM_SEPOLIA] = FINAL[EChainID.ARBITRUM]; // Copy from Arbitrum
FINAL[EChainID.SEPOLIA] = FINAL[EChainID.ARBITRUM]; // Copy from Arbitrum
FINAL['31337' as EChainID] = FINAL[EChainID.ARBITRUM]; // Copy from Arbitrum

type TMisc = {
    [key in EChainID]?: {
        CL_SEQUENCER: string;
        WETH: string;
        USDC: string;
    };
};
const MISC: TMisc = {
    [EChainID.ARBITRUM]: {
        CL_SEQUENCER: '0xFdB631F5EE196F0ed6FAa767959853A9F217697D', // Arbitrum mainnet ChainLink sequencer uptime feed
        WETH: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
        USDC: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
    },
};
MISC[EChainID.ARBITRUM_SEPOLIA] = MISC[EChainID.ARBITRUM]; // Copy from Arbitrum
MISC[EChainID.SEPOLIA] = MISC[EChainID.ARBITRUM]; // Copy from Arbitrum

export const DEPLOY_CONFIG = {
    POST_LBP,
    FINAL,
    MISC,
};
