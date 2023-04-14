// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IMarketHelper {
    function depositAddCollateralAndBorrow(
        address market,
        address _user,
        uint256 _collateralAmount,
        uint256 _borrowAmount,
        bool extractFromSender,
        bool deposit_,
        bool withdraw_,
        bytes calldata _withdrawData
    ) external payable;

    function depositAndAddAsset(
        address singularity,
        address _user,
        uint256 _amount,
        bool deposit_,
        bool extractFromSender
    ) external;
}
