// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IMagnetar {
    function withdrawTo(
        address yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        uint256 share,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas
    ) external payable;

    function depositAndRepay(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        bool deposit,
        bool extractFromSender
    ) external payable;

    function depositRepayAndRemoveCollateral(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool deposit,
        bool withdraw,
        bool extractFromSender
    ) external payable;

    function mintAndLend(
        address singularity,
        address bingBang,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool deposit,
        bool extractFromSender
    ) external payable;

    function depositAndAddAsset(
        address singularity,
        address _user,
        uint256 _amount,
        bool deposit_,
        bool extractFromSender
    ) external payable;

    function removeAssetAndRepay(
        address singularity,
        address bingBang,
        address user,
        uint256 removeShare, //slightly greater than _repayAmount to cover the interest
        uint256 repayAmount,
        uint256 collateralShare,
        bool withdraw,
        bytes calldata withdrawData
    ) external payable;

    function depositAddCollateralAndBorrow(
        address market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        bool withdraw,
        bytes memory withdrawData
    ) external payable;
}
