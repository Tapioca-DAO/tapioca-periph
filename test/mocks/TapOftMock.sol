// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TapOftMock is ERC20 {
    constructor() ERC20("ERC-20C Mock", "MOCK") {}

    function extractTAP(address to, uint256 value) external {
        _mint(to, value);
    }

    function ownerOf(uint256) external view returns (address) {
        return msg.sender;
    }
}
