// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Weth9Mock is ERC20 {
    constructor() ERC20("ERC-20C Mock", "MOCK") {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }
}
