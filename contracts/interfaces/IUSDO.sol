// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IUSDO is IERC20Metadata {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}
