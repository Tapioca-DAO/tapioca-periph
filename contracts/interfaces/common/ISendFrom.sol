// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {ICommonData} from "./ICommonData.sol";
import {ICommonOFT} from "./ICommonOFT.sol";

interface ISendFrom {
    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes32 toAddress,
        uint256 amount,
        ICommonOFT.LzCallParams calldata callParams
    ) external payable;

    function useCustomAdapterParams() external view returns (bool);
}
