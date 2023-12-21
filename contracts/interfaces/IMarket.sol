// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IMarket {
    function asset() external view returns (address);

    function assetId() external view returns (uint256);

    function collateral() external view returns (address);

    function collateralId() external view returns (uint256);

    function totalBorrowCap() external view returns (uint256);

    function totalCollateralShare() external view returns (uint256);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function totalBorrow()
        external
        view
        returns (uint128 elastic, uint128 base);

    function oracle() external view returns (address);

    function oracleData() external view returns (bytes memory);

    function exchangeRate() external view returns (uint256);

    function yieldBox() external view returns (address payable);

    function liquidationMultiplier() external view returns (uint256);

    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 amount,
        uint256 share
    ) external;

    function removeCollateral(address from, address to, uint256 share) external;

    function addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function borrow(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 part, uint256 share);

    function execute(
        bytes[] calldata calls,
        bool revertOnFail
    ) external returns (bool[] memory successes, string[] memory results);

    function refreshPenroseFees() external returns (uint256 feeShares);

    function penrose() external view returns (address);

    function owner() external view returns (address);

    function collateralizationRate() external view returns (uint256);

    function buyCollateral(
        address from,
        uint256 borrowAmount,
        uint256 supplyAmount,
        bytes calldata data
    ) external returns (uint256 amountOut);

    function sellCollateral(
        address from,
        uint256 share,
        bytes calldata data
    ) external returns (uint256 amountOut);
}
