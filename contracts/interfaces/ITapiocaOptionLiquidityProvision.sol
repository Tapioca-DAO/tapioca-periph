// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ITapiocaOptionLiquidityProvision {
    struct IOptionsLockData {
        bool lock;
        address target;
        uint128 lockDuration;
        uint128 amount;
    }

    function yieldBox() external view returns (address);

    function activeSingularities(
        address singularity
    )
        external
        view
        returns (
            uint256 sglAssetId,
            uint256 totalDeposited,
            uint256 poolWeight
        );

    function lock(
        address to,
        address singularity,
        uint128 lockDuration,
        uint128 amount
    ) external returns (uint256 tokenId);
}
