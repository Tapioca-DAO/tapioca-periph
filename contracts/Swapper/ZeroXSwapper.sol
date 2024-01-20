// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

/// @notice swaps a token for another, using 0x as a swap aggregator
/// @dev All of the parameters below are provided by the API response.
/// @param sellToken the token to sell
/// @param buyToken the token to buy
/// @param swapTarget the 0x swap proxy
/// @param swapCallData the swap call data
/// @return amountOut the amount of buyToken bought
struct SZeroXSwapData {
    IERC20 sellToken;
    IERC20 buyToken;
    address payable swapTarget;
    bytes swapCallData;
}

/// @title ZeroX swapper
contract ZeroXSwapper {
    using SafeERC20 for IERC20;
    /// ************
    /// *** VARS ***
    /// ************

    address public zeroXProxy;

    /// **************
    /// *** ERRORS ***
    /// **************

    error ZeroAddress();
    error InvalidProxy();
    error SwapFailed();
    error MinSwapFailed();

    constructor(address _zeroXProxy) {
        if (_zeroXProxy == address(0)) revert ZeroAddress();
        zeroXProxy = _zeroXProxy;
    }

    /// **********************
    /// *** PUBLIC METHODS ***
    /// **********************

    /// @notice swaps a token for another, using 0x as a swap aggregator
    /// @param swapData the swap data
    /// @param amountIn the amount of sellToken to sell
    /// @param minAmountOut the minimum amount of buyToken bought
    /// @return amountOut the amount of buyToken bought
    function swap(
        SZeroXSwapData calldata swapData,
        uint256 amountIn,
        uint256 minAmountOut
    ) public payable returns (uint256 amountOut) {
        if (swapData.swapTarget != zeroXProxy) revert InvalidProxy();

        // Transfer tokens to this contract
        swapData.sellToken.safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        // Approve the 0x proxy to spend the sell token
        swapData.sellToken.safeApprove(swapData.swapTarget, amountIn);
        (bool success, ) = swapData.swapTarget.call(swapData.swapCallData);
        if (!success) revert SwapFailed();

        // Check that the amountOut is at least as much as minAmountOut
        amountOut = swapData.buyToken.balanceOf(address(this));
        if (amountOut < minAmountOut) revert MinSwapFailed();

        // Transfer the bought tokens to the sender
        swapData.buyToken.safeTransfer(msg.sender, amountOut);
    }
}
