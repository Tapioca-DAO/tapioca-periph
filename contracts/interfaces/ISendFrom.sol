// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ISendFrom {
    struct LzCallParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
        bool unwrapOnDestination;
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        LzCallParams calldata _callParams
    ) external payable;

    function useCustomAdapterParams() external view returns (bool);
}
