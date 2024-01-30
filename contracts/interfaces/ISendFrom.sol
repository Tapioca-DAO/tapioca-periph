// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ICommonOFT} from "../../gitsub_tapioca-sdk/src/contracts/token/oft/v2/ICommonOFT.sol";
import "./ICommonData.sol";

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
