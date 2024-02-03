pragma solidity ^0.8.9;

import "forge-std/StdCheats.sol";
import "forge-std/StdAssertions.sol";
import "forge-std/StdUtils.sol";
import {TestBase} from "forge-std/Base.sol";

import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {ERC721Mock} from "../mocks/ERC721Mock.sol";
import {ERC1155Mock} from "../mocks/ERC1155Mock.sol";

import {Pearlmit} from "tapioca-periph/pearlmit/Pearlmit.sol";

import "forge-std/console.sol";

contract PearlmitBaseTest is TestBase, StdAssertions, StdCheats, StdUtils {
    Pearlmit pearlmit;

    uint256 adminKey;
    uint256 aliceKey;
    uint256 bobKey;
    uint256 carolKey;

    address admin;
    address alice;
    address bob;
    address carol;

    uint256 constant INITIAL_TIMESTAMP = 1703688340;

    function setUp() public virtual {
        pearlmit = new Pearlmit("Pearlmit", "1");

        (admin, adminKey) = makeAddrAndKey("admin");
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        (carol, carolKey) = makeAddrAndKey("carol");

        // Warp to a more realistic timestamp
        vm.warp(INITIAL_TIMESTAMP);
    }

    function _deployNew721(address to, uint256 idToMint) internal virtual returns (address) {
        address token = address(new ERC721Mock());
        ERC721Mock(token).mint(to, idToMint);
        return token;
    }

    function _deployNew1155(address to, uint256 idToMint, uint256 amountToMint) internal virtual returns (address) {
        address token = address(new ERC1155Mock());
        ERC1155Mock(token).mint(to, idToMint, amountToMint);
        return token;
    }

    function _deployNew20(address to, uint256 amountToMint) internal virtual returns (address) {
        address token = address(new ERC20Mock());
        ERC20Mock(token).mint(to, amountToMint);
        return token;
    }

    function _mint721(address tokenAddress, address to, uint256 tokenId) internal virtual {
        ERC721Mock(tokenAddress).mint(to, tokenId);
    }

    function _mint20(address tokenAddress, address to, uint256 amount) internal virtual {
        ERC20Mock(tokenAddress).mint(to, amount);
    }

    function _mint1155(address tokenAddress, address to, uint256 tokenId, uint256 amount) internal virtual {
        ERC1155Mock(tokenAddress).mint(to, tokenId, amount);
    }
}
