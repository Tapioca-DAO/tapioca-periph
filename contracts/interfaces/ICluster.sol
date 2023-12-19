// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ICluster {
    function isWhitelisted(
        uint16 lzChainId,
        address _addr
    ) external view returns (bool);

    function updateContract(
        uint16 lzChainId,
        address _addr,
        bool _status
    ) external;

    function batchUpdateContracts(
        uint16 _lzChainId,
        address[] memory _addresses,
        bool _status
    ) external;

    function lzChainId() external view returns (uint16);
}
