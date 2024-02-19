// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IZeroXSwapper {
    /// @notice swaps a token for another, using 0x as a swap aggregator
    /// @dev All of the parameters below are provided by the API response.
    /// @param sellToken the token to sell
    /// @param buyToken the token to buy
    /// @param swapTarget the 0x swap proxy
    /// @param swapCallData the swap call data. Either 0x or 1inch
    /// @return amountOut the amount of buyToken bought
    struct SZeroXSwapData {
        IERC20 sellToken;
        IERC20 buyToken;
        address payable swapTarget;
        bytes swapCallData;
    }

    /// @notice swaps a token for another, using 0x as a swap aggregator
    /// @dev All of the parameters below are provided by the API response.
    /// @param swapData the swap data
    /// @param amountIn the amount of sellToken to sell
    /// @param minAmountOut the minimum amount of buyToken bought
    /// @return amountOut the amount of buyToken bought
    function swap(SZeroXSwapData calldata swapData, uint256 amountIn, uint256 minAmountOut)
        external
        payable
        returns (uint256 amountOut);
}
