// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPearlmit, PearlmitHandler} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITap} from "tapioca-periph/interfaces/oft/ITap.sol";

contract TapiocaOptionsLiquidityProvisionMock is PearlmitHandler, ERC721 {
    uint256 public sglAssetId;
    address public yieldBox;

    error TransferFailed();

    struct SingularityPool {
        uint256 sglAssetID; // Singularity market YieldBox asset ID
        uint256 totalDeposited; // total amount of YieldBox shares deposited, used for pool share calculation
        uint256 poolWeight; // Pool weight to calculate emission
        bool rescue; // If true, the pool will be used to rescue funds in case of emergency
    }

    constructor(uint256 _sglAssetId, address _yb, IPearlmit _pearlmit) PearlmitHandler(_pearlmit) ERC721("tOLP Mock", "MOCK") {
        sglAssetId = _sglAssetId;
        yieldBox = _yb;
    }

    function lock(address _to, IERC20 _singularity, uint128 _lockDuration, uint128 _ybShares)
        external
        returns (uint256 tokenId)
    {
        bool isErr = pearlmit.transferFromERC1155(msg.sender, address(this), yieldBox, sglAssetId, _ybShares);
        if (isErr) {
            revert TransferFailed();
        }

        _mint(_to, 1);

        return 1;
    }

    function activeSingularities(address _sgl) external view returns (uint256, uint256, uint256, bool) {
        return (sglAssetId, 0, 0, false);
    }


    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
        return 0xf23a6e61;
    }
}