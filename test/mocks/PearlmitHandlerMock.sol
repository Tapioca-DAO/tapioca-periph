// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {PearlmitHandler} from "../../contracts/pearlmit/PearlmitHandler.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {PearlmitHash} from "../../contracts/pearlmit/PearlmitHash.sol";

/**
 * @title PearlmitHandlerMock
 * @dev A mock contract for testing internal PearlmitHandler functions for ERC20 and ERC721 approvals.
 */
contract PearlmitHandlerMock is PearlmitHandler {
    constructor(IPearlmit _pearlmit) PearlmitHandler(_pearlmit) {}

    function isERC721Approved_(address _owner, address spender, address token, uint256 id)
        external
        view
        returns (bool)
    {
        bool isApproved = isERC721Approved(_owner, spender, token, id);
        return (isApproved);
    }

    function isERC20Approved_(address _owner, address spender, address token, uint256 amount)
        external
        view
        returns (bool)
    {
        bool isApproved = isERC20Approved(_owner, spender, token, amount);
        return (isApproved);
    }
}
