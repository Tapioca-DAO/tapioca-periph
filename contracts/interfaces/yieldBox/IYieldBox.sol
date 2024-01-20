// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}

interface IYieldBox {
    function wrappedNative() external view returns (address wrappedNative);

    function assets(uint256 assetId)
        external
        view
        returns (TokenType tokenType, address contractAddress, address strategy, uint256 tokenId);

    function nativeTokens(uint256 assetId)
        external
        view
        returns (string memory name, string memory symbol, uint8 decimals);

    function owner(uint256 assetId) external view returns (address owner);

    function totalSupply(uint256 assetId) external view returns (uint256 totalSupply);

    function setApprovalForAsset(address operator, uint256 assetId, bool approved) external;

    function depositAsset(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function withdraw(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function transfer(address from, address to, uint256 assetId, uint256 share) external;

    function batchTransfer(address from, address to, uint256[] calldata assetIds_, uint256[] calldata shares_)
        external;

    function transferMultiple(address from, address[] calldata tos, uint256 assetId, uint256[] calldata shares)
        external;

    function toShare(uint256 assetId, uint256 amount, bool roundUp) external view returns (uint256 share);

    function toAmount(uint256 assetId, uint256 share, bool roundUp) external view returns (uint256 amount);
}
