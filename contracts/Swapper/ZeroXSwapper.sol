// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {IZeroXSwapper} from "tapioca-periph/interfaces/periph/IZeroXSwapper.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/// @title ZeroX swapper
contract ZeroXSwapper is IZeroXSwapper, Ownable {
    using SafeERC20 for IERC20;

    /// ************
    /// *** VARS ***
    /// ************

    address public zeroXProxy;
    address public oneInchProxy;
    ICluster public cluster;

    bool public isOneInchEnabled;

    /// **************
    /// *** ERRORS ***
    /// **************

    error ZeroAddress();
    error InvalidProxy(address actual, address expected);
    error SwapFailed();
    error MinSwapFailed(uint256 amountOut);
    error SenderNotValid(address sender);

    constructor(address _zeroXProxy, address _oneInchProxy, ICluster _cluster, address _owner) {
        if (_zeroXProxy == address(0)) revert ZeroAddress();
        zeroXProxy = _zeroXProxy;
        oneInchProxy = _oneInchProxy;
        cluster = _cluster;
        transferOwnership(_owner);
    }

    /// **********************
    /// *** PUBLIC METHODS ***
    /// **********************

    /// @notice swaps a token for another, using 0x as a swap aggregator
    /// @dev All of the parameters below are provided by the API response.
    /// @param swapData the swap data. Either 0x or 1inch
    /// @param amountIn the amount of sellToken to sell
    /// @param minAmountOut the minimum amount of buyToken bought
    /// @return amountOut the amount of buyToken bought
    function swap(SZeroXSwapData calldata swapData, uint256 amountIn, uint256 minAmountOut)
        public
        payable
        returns (uint256 amountOut)
    {
        if (!cluster.isWhitelisted(0, msg.sender)) revert SenderNotValid(msg.sender);

        // Transfer tokens to this contract
        swapData.sellToken.safeTransferFrom(msg.sender, address(this), amountIn);

        if (!isOneInchEnabled && swapData.swapTarget != zeroXProxy) {
            revert InvalidProxy(swapData.swapTarget, zeroXProxy);
        } else if (isOneInchEnabled && swapData.swapTarget != oneInchProxy) {
            revert InvalidProxy(swapData.swapTarget, oneInchProxy);
        }

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

    /// @notice updates the swap function to use 1inch instead of 0x.
    function setIsOneInchEnabled(bool _isOneInchEnabled) external onlyOwner {
        isOneInchEnabled = _isOneInchEnabled;
    }

    /**
     * @notice Payable fallback to allow this contract to receive protocol fee refunds.
     * https://0x.org/docs/0x-swap-api/guides/use-0x-api-liquidity-in-your-smart-contracts#payable-fallback
     */
    receive() external payable {}
}
