// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

abstract contract BaseToeMsgType {
    // LZ
    uint16 public constant MSG_SEND = 1;
    // Tapioca
    uint16 public constant MSG_APPROVALS = 500;
    uint16 public constant MSG_NFT_APPROVALS = 501;

    uint16 public constant MSG_REMOTE_TRANSFER = 700;
}
