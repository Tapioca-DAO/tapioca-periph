// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {ICommonData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {ICommonOFT} from "tapioca-periph/interfaces/common/ICommonOFT.sol";
import {ISendFrom} from "tapioca-periph/interfaces/common/ISendFrom.sol";
import {IUSDOBase} from "tapioca-periph/interfaces/bar/IUSDO.sol";

interface ITapiocaOFTBase {
    function hostChainID() external view returns (uint256);

    function wrap(address fromAddress, address toAddress, uint256 amount) external payable returns (uint256 minted);

    function unwrap(address _toAddress, uint256 _amount) external;

    function erc20() external view returns (address);

    function lzEndpoint() external view returns (address);

    function vault() external view returns (address);
}

/// @dev used for generic TOFTs
interface ITapiocaOFT is ISendFrom, ITapiocaOFTBase {
    struct IRemoveParams {
        uint256 amount;
        address marketHelper;
        address market;
    }

    struct IBorrowParams {
        uint256 amount;
        uint256 borrowAmount;
        address marketHelper;
        address market;
        bool deposit;
    }

    function totalFees() external view returns (uint256);

    function erc20() external view returns (address);

    function wrappedAmount(uint256 _amount) external view returns (uint256);

    function isHostChain() external view returns (bool);

    function balanceOf(address _holder) external view returns (uint256);

    function isTrustedRemote(uint16 lzChainId, bytes calldata path) external view returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function extractUnderlying(uint256 _amount) external;

    function harvestFees() external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
