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
    function _asset() external view returns (address);

    function _assetId() external view returns (uint256);

    function _collateral() external view returns (address);

    function _collateralId() external view returns (uint256);

    function _totalBorrowCap() external view returns (uint256);

    function _totalCollateralShare() external view returns (uint256);

    function _userBorrowPart(address) external view returns (uint256);

    function _userCollateralShare(address) external view returns (uint256);

    function _totalBorrow() external view returns (uint128 elastic, uint128 base);

    function _oracle() external view returns (address);

    function _oracleData() external view returns (bytes memory);

    function _exchangeRate() external view returns (uint256);

    function _liquidationMultiplier() external view returns (uint256);

    function _penrose() external view returns (address);

    function _collateralizationRate() external view returns (uint256);

    function _liquidationBonusAmount() external view returns (uint256);

    function _liquidationCollateralizationRate() external view returns (uint256);

    function _yieldBox() external view returns (address payable);

    function _exchangeRatePrecision() external view returns (uint256);

    function _minBorrowAmount() external view returns (uint256);

    function _minCollateralAmount() external view returns (uint256);

    function _minLendAmount () external view returns (uint256); //available on SGL only


    function computeClosingFactor(uint256 borrowPart, uint256 collateralPartInAsset, uint256 ratesPrecision)
        external
        view
        returns (uint256);

    function refreshPenroseFees() external returns (uint256 feeShares);

    function updateExchangeRate() external;
    
    function accrue() external;

    function owner() external view returns (address);

    function execute(Module[] calldata modules, bytes[] calldata calls, bool revertOnFail)
        external
        returns (bool[] memory successes, bytes[] memory results);

    function updatePause(uint256 _type, bool val) external;

    function updatePauseAll(bool val) external; //Not available for Singularity
}
