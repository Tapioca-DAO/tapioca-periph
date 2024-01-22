// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseOFTWithFee.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ProxyOFTWithFee is BaseOFTWithFee {
    using SafeERC20 for IERC20;

    IERC20 internal immutable innerToken;
    uint256 internal immutable ld2sdRate;

    // total amount is transferred from this chain to other chains, ensuring the total is less than uint64.max in sd
    uint256 public outboundAmount;

    constructor(address _token, uint8 _sharedDecimals, address _lzEndpoint)
        BaseOFTWithFee(_sharedDecimals, _lzEndpoint)
    {
        innerToken = IERC20(_token);

        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("decimals()"));
        require(success, "ProxyOFTWithFee: failed to get token decimals");
        uint8 decimals = abi.decode(data, (uint8));

        require(_sharedDecimals <= decimals, "ProxyOFTWithFee: sharedDecimals must be <= decimals");
        ld2sdRate = 10 ** (decimals - _sharedDecimals);
    }

    /**
     *
     * public functions
     *
     */
    function circulatingSupply() public view virtual override returns (uint256) {
        return innerToken.totalSupply() - outboundAmount;
    }

    function token() public view virtual override returns (address) {
        return address(innerToken);
    }

    /**
     *
     * internal functions
     *
     */
    function _debitFrom(address _from, uint16, bytes32, uint256 _amount) internal virtual override returns (uint256) {
        require(_from == _msgSender(), "ProxyOFTWithFee: owner is not send caller");

        _amount = _transferFrom(_from, address(this), _amount);

        // _amount still may have dust if the token has transfer fee, then give the dust back to the sender
        (uint256 amount, uint256 dust) = _removeDust(_amount);
        if (dust > 0) innerToken.safeTransfer(_from, dust);

        // check total outbound amount
        outboundAmount += amount;
        uint256 cap = _sd2ld(type(uint64).max);
        require(cap >= outboundAmount, "ProxyOFTWithFee: outboundAmount overflow");

        return amount;
    }

    function _creditTo(uint16, address _toAddress, uint256 _amount) internal virtual override returns (uint256) {
        outboundAmount -= _amount;

        // tokens are already in this contract, so no need to transfer
        if (_toAddress == address(this)) {
            return _amount;
        }

        return _transferFrom(address(this), _toAddress, _amount);
    }

    function _transferFrom(address _from, address _to, uint256 _amount) internal virtual override returns (uint256) {
        uint256 before = innerToken.balanceOf(_to);
        if (_from == address(this)) {
            innerToken.safeTransfer(_to, _amount);
        } else {
            innerToken.safeTransferFrom(_from, _to, _amount);
        }
        return innerToken.balanceOf(_to) - before;
    }

    function _ld2sdRate() internal view virtual override returns (uint256) {
        return ld2sdRate;
    }
}
