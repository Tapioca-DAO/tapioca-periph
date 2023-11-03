import { HardhatRuntimeEnvironment } from 'hardhat/types';
import _ from 'lodash';
import { SeerCLSolo__factory, Seer__factory } from '../typechain';

export const loadVM = async (
    hre: HardhatRuntimeEnvironment,
    tag: string,
    debugMode = true,
) => {
    const isLocal = hre.network.config.tags.includes('local');
    const VM = new hre.SDK.DeployerVM(hre, {
        // Change this if you get bytecode size error / gas required exceeds allowance (550000000)/ anything related to bytecode size
        // Could be different by network/RPC provider
        bytecodeSizeLimit: 100_000,
        ...(isLocal ? { globalWait: 0 } : {}),
        debugMode,
        tag,
    });
    return VM;
};

export const nonNullValues = <T>(args: Array<any>) => {
    for (let i = 0; i < args.length; i++) {
        if (_.isNil(args[i])) {
            throw `[-] Argument ${i} is null`;
        }
    }
};

export const displaySeerArgs = (args: Parameters<Seer__factory['deploy']>) => {
    let i = 0;
    console.log('[+] With args:');
    console.log(`\t[${i}]Name:`, args[i++]);
    console.log(`\t[${i}]Symbol:`, args[i++]);
    console.log(`\t[${i}]Decimal:`, args[i++]);
    console.log(`\t[${i}]Addresses:`, args[i++]);
    console.log(`\t[${i}]LP:`, args[i++]);
    console.log(`\t[${i}]Multiply/divide Uni:`, args[i++]);
    console.log(`\t[${i}]TWAP:`, args[i++]);
    console.log(`\t[${i}]Uni min observation length:`, args[i++]);
    console.log(`\t[${i}]ChainLink usage:`, args[i++]);
    console.log(`\t[${i}]ChainLink path:`, args[i++]);
    console.log(`\t[${i}]Multiply/Divide ChainLink:`, args[i++]);
    console.log(`\t[${i}]ChainLink stale period(in seconds):`, args[i++]);
    console.log(`\t[${i}]Guardians:`, args[i++]);
    console.log(`\t[${i}]Description:`, args[i++]);
    console.log(`\t[${i}]ChainLink sequencer:`, args[i++]);
    console.log(`\t[${i}]Admins:`, args[i++]);
};

export const displaySeerCLSoloArgs = (
    args: Parameters<SeerCLSolo__factory['deploy']>,
) => {
    let i = 0;
    console.log('[+] With args:');
    console.log(`\t[${i}]Name:`, args[i++]);
    console.log(`\t[${i}]Symbol:`, args[i++]);
    console.log(`\t[${i}]Decimal:`, args[i++]);
    console.log(`\t[${i}]LP:`, args[i++]);
    console.log(`\t[${i}]Multiply/divide Uni:`, args[i++]);
    console.log(`\t[${i}]Guardians:`, args[i++]);
    console.log(`\t[${i}]Description:`, args[i++]);
    console.log(`\t[${i}]ChainLink sequencer:`, args[i++]);
    console.log(`\t[${i}]Admins:`, args[i++]);
};
