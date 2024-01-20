// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "tapioca-sdk/dist/contracts/YieldBox/contracts/enums/YieldBoxTokenType.sol";

interface IYieldBoxBase {
    function depositAsset(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function depositETHAsset(uint256 assetId, address to, uint256 amount)
        external
        payable
        returns (uint256 amountOut, uint256 shareOut);

    function withdraw(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function transfer(address from, address to, uint256 assetId, uint256 share) external;

    function isApprovedForAll(address user, address spender) external view returns (bool);

    function setApprovalForAll(address spender, bool status) external;

    function setApprovalForAsset(address operator, uint256 assetId, bool approved) external;

    function assets(uint256 assetId)
        external
        view
        returns (TokenType tokenType, address contractAddress, address strategy, uint256 tokenId);

    function assetTotals(uint256 assetId) external view returns (uint256 totalShare, uint256 totalAmount);

    function toShare(uint256 assetId, uint256 amount, bool roundUp) external view returns (uint256 share);

    function toAmount(uint256 assetId, uint256 share, bool roundUp) external view returns (uint256 amount);

    function balanceOf(address user, uint256 assetId) external view returns (uint256 share);
}
