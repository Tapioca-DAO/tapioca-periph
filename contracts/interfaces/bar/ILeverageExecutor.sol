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

interface ILeverageExecutor {
    function swapper() external view returns (address);

    function cluster() external view returns (address);

    function yieldBox() external view returns (address);

    function getCollateral(address refundDustAddress, address assetAddress, address collateralAddress, uint256 assetAmountIn, bytes calldata data)
        external
        returns (uint256 collateralAmountOut); //used for buyCollateral

    function getAsset(address refundDustAddress, address collateralAddress, address assetAddress, uint256 collateralAmountIn, bytes calldata data)
        external
        returns (uint256 assetAmountOut); //used for sellCollateral
}
