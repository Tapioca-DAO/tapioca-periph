// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/// @notice enum representing each type of module associated with a Singularity market
/// @dev modules are contracts that holds a portion of the market's logic
enum Module {
    Base,
    Borrow,
    Collateral,
    Liquidation,
    Leverage
}

interface IMarket {
    function asset() external view returns (address);

    function assetId() external view returns (uint256);

    function collateral() external view returns (address);

    function collateralId() external view returns (uint256);

    function totalBorrowCap() external view returns (uint256);

    function totalCollateralShare() external view returns (uint256);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function totalBorrow() external view returns (uint128 elastic, uint128 base);

    function oracle() external view returns (address);

    function oracleData() external view returns (bytes memory);

    function exchangeRate() external view returns (uint256);

    function yieldBox() external view returns (address payable);

    function liquidationMultiplier() external view returns (uint256);

    function refreshPenroseFees() external returns (uint256 feeShares);

    function penrose() external view returns (address);

    function owner() external view returns (address);

    function collateralizationRate() external view returns (uint256);

    function execute(Module[] calldata modules, bytes[] calldata calls, bool revertOnFail)
        external
        returns (bool[] memory successes, bytes[] memory results);

    function liquidationBonusAmount() external view returns (uint256);
    function liquidationCollateralizationRate() external view returns (uint256);
}
