// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

interface IMagnetarHelper {
    function getAmountForBorrowPart(
        address market,
        uint256 borrowPart
    ) external view returns (uint256 amount);

    function getBorrowPartForAmount(
        address market,
        uint256 amount
    ) external view returns (uint256 part);
}
