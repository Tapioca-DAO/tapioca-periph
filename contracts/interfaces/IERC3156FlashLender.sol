// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);

    function flashFee(address token, uint256 amount) external view returns (uint256);

    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool);
}
