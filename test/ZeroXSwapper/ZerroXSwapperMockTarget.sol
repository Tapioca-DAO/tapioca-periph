// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

contract ZerroXSwapperMockTarget {
    bool public state = true;

    receive() external payable {}

    function toggleState() public payable {
        state = !state;
    }
}
