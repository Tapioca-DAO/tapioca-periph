// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {IMarketLiquidatorReceiver} from "./IMarketLiquidatorReceiver.sol";
import {Module} from "./IMarket.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IMarketHelper {
    function computeAllowedLendShare(address sglAddress, uint256 amount, uint256 tokenId)
        external
        view
        returns (uint256 share);

    function getLiquidationCollateralAmount(
        address sglAddress,
        address user,
        uint256 maxBorrowPart,
        uint256 minLiquidationBonus,
        uint256 exchangeRatePrecision,
        uint256 feeDecimalsPrecision
    ) external view returns (Module[] memory modules, bytes[] memory calls);

    function getLiquidationCollateralAmountView(bytes calldata result) external pure returns (uint256 amount);

    function addCollateral(address from, address to, bool skim, uint256 amount, uint256 share)
        external
        pure
        returns (Module[] memory modules, bytes[] memory calls);

    function removeCollateral(address from, address to, uint256 share)
        external
        pure
        returns (Module[] memory modules, bytes[] memory calls);

    function borrow(address from, address to, uint256 amount)
        external
        pure
        returns (Module[] memory modules, bytes[] memory calls);
    function borrowView(bytes calldata result) external pure returns (uint256 part, uint256 share);

    function repay(address from, address to, bool skim, uint256 part)
        external
        pure
        returns (Module[] memory modules, bytes[] memory calls);

    function repayView(bytes calldata result) external pure returns (uint256 amount);

    function sellCollateral(address from, uint256 share, bytes calldata data)
        external
        pure
        returns (Module[] memory modules, bytes[] memory calls);

    function sellCollateralView(bytes calldata result) external pure returns (uint256 amountOut);

    function buyCollateral(address from, uint256 borrowAmount, uint256 supplyAmount, bytes calldata data)
        external
        pure
        returns (Module[] memory modules, bytes[] memory calls);
    function buyCollateralView(bytes calldata result) external pure returns (uint256 amountOut);

    function liquidateBadDebt(
        address user,
        address from,
        address receiver,
        IMarketLiquidatorReceiver liquidatorReceiver,
        bytes calldata liquidatorReceiverData,
        bool swapCollateral
    ) external pure returns (Module[] memory modules, bytes[] memory calls);

    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        uint256[] calldata minLiquidationBonuses,
        IMarketLiquidatorReceiver[] calldata liquidatorReceivers,
        bytes[] calldata liquidatorReceiverDatas
    ) external pure returns (Module[] memory modules, bytes[] memory calls);
}
