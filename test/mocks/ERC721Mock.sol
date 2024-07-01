// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721 {
    constructor() ERC721("ERC-721C Mock", "MOCK") {}

    
    struct TapOption {
        uint128 entry; // time when the option position was created
        uint128 expiry; // timestamp, as once one wise man said, the sun will go dark before this overflows
        uint128 discount; // discount in basis points
        uint256 tOLP; // tOLP token ID
    }


    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function attributes(uint256 id) external view returns (address, TapOption memory) {
        return (address(0), TapOption(1,1,1,1));
    }
}
