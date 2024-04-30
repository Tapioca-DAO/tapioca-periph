// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    SendParam,
    MessagingFee,
    MessagingReceipt,
    OFTReceipt
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
contract ERC20Mock is ERC20 {
    constructor() ERC20("ERC-20C Mock", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    function combineOptions(uint32, uint16, bytes calldata)
        external
        pure
        returns (bytes memory)
        {
            return "0x";
        }
    function quoteSendPacket(
        SendParam calldata,
        bytes calldata,
        bool,
        bytes calldata,
        bytes calldata /*_oftCmd*/ // @dev unused in the default implementation.
    ) external pure returns (MessagingFee memory msgFee) {
        return MessagingFee({lzTokenFee: 0, nativeFee: 0});
    }
}
