// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ICommonOFT} from "tapioca-sdk/dist/contracts/token/oft/v2/ICommonOFT.sol";

interface ISendFrom {
    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes32 toAddress,
        uint256 amount,
        ICommonOFT.LzCallParams calldata callParams
    ) external payable;

     function sendFromWithParams(
        address from,
        uint16 lzDstChainId,
        bytes32 toAddress,
        uint256 amount,
        ICommonOFT.LzCallParams calldata callParams,
        bool unwrap
    ) external payable;

    function useCustomAdapterParams() external view returns (bool);
}
