// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ICluster {
    enum WhitelistType {
        Market,
        TOFT,
        Magnetar,
        Oracle,
        Swapper
    }

    function isWhitelisted(
        WhitelistType whitelistType,
        uint16 lzChainId,
        address _addr
    ) external view returns (bool);

    function updateContract(
        WhitelistType whitelistType,
        uint16 lzChainId,
        address _addr,
        bool _status
    ) external;
}
