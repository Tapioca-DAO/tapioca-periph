// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Tapioca
import {IZeroXSwapper} from "tapioca-periph/interfaces/periph/IZeroXSwapper.sol";
import {ICluster} from "tapioca-periph/interfaces/ICluster.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title ZeroX swapper
contract ZeroXSwapper is IZeroXSwapper {
    using SafeERC20 for IERC20;

    /// ************
    /// *** VARS ***
    /// ************

    address public zeroXProxy;
    ICluster public cluster;

    /// **************
    /// *** ERRORS ***
    /// **************

    error ZeroAddress();
    error InvalidProxy(address actual, address expected);
    error SwapFailed();
    error MinSwapFailed(uint256 amountOut);
    error SenderNotValid(address sender);

    constructor(address _zeroXProxy, ICluster _cluster) {
        if (_zeroXProxy == address(0)) revert ZeroAddress();
        zeroXProxy = _zeroXProxy;
        cluster = _cluster;
    }

    /// **********************
    /// *** PUBLIC METHODS ***
    /// **********************

    /// @notice swaps a token for another, using 0x as a swap aggregator
    /// @dev All of the parameters below are provided by the API response.
    /// @param swapData the swap data
    /// @param amountIn the amount of sellToken to sell
    /// @param minAmountOut the minimum amount of buyToken bought
    /// @return amountOut the amount of buyToken bought
    function swap(SZeroXSwapData calldata swapData, uint256 amountIn, uint256 minAmountOut)
        public
        payable
        returns (uint256 amountOut)
    {
        if (!cluster.isWhitelisted(0, msg.sender)) revert SenderNotValid(msg.sender);

        if (swapData.swapTarget != zeroXProxy) revert InvalidProxy(swapData.swapTarget, zeroXProxy);

        // Transfer tokens to this contract
        swapData.sellToken.safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve the 0x proxy to spend the sell token, and call the swap function
        swapData.sellToken.safeApprove(swapData.swapTarget, amountIn);
        (bool success,) = swapData.swapTarget.call(swapData.swapCallData);
        if (!success) revert SwapFailed();
        swapData.sellToken.safeApprove(swapData.swapTarget, 0);

        // Check that the amountOut is at least as much as minAmountOut
        amountOut = swapData.buyToken.balanceOf(address(this));
        if (amountOut < minAmountOut) revert MinSwapFailed(amountOut);

        // Transfer the bought tokens to the sender
        swapData.buyToken.safeTransfer(msg.sender, amountOut);
    }

    /**
     * @notice Payable fallback to allow this contract to receive protocol fee refunds.
     * https://0x.org/docs/0x-swap-api/guides/use-0x-api-liquidity-in-your-smart-contracts#payable-fallback
     */
    receive() external payable {}
}
