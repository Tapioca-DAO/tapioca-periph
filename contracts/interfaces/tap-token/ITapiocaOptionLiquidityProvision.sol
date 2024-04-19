// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ITapiocaOptionLiquidityProvision is IERC721 {
    function yieldBox() external view returns (address);

    function activeSingularities(address singularity)
        external
        view
        returns (uint256 sglAssetId, uint256 totalDeposited, uint256 poolWeight);

    function lock(address to, address singularity, uint128 lockDuration, uint128 amount)
        external
        returns (uint256 tokenId);

    function unlock(uint256 tokenId, address singularity, address to) external returns (uint256 sharesOut);
}

struct IOptionsLockData {
    bool lock;
    address target;
    uint128 lockDuration;
    uint128 amount;
    uint256 fraction;
}

struct IOptionsUnlockData {
    bool unlock;
    address target;
    uint256 tokenId;
}
