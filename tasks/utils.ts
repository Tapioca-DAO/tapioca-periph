import { HardhatRuntimeEnvironment } from 'hardhat/types';

export const loadVM = async (hre: HardhatRuntimeEnvironment, tag?: string) => {
    const VM = new hre.SDK.DeployerVM(hre, {
        // Change this if you get bytecode size error / gas required exceeds allowance (550000000)/ anything related to bytecode size
        // Could be different by network/RPC provider
        bytecodeSizeLimit: 100_000,
        debugMode: true,
        tag,
    });
    return VM;
};
