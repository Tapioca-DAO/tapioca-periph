// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external payable;
}
