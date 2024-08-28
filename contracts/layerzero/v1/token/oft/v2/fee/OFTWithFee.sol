// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BaseOFTWithFee.sol";

contract OFTWithFee is BaseOFTWithFee, ERC20 {
    uint256 internal immutable ld2sdRate;

    constructor(string memory _name, string memory _symbol, uint8 _sharedDecimals, address _lzEndpoint)
        ERC20(_name, _symbol)
        BaseOFTWithFee(_sharedDecimals, _lzEndpoint)
    {
        uint8 decimals = decimals();
        require(_sharedDecimals <= decimals, "OFTWithFee: sharedDecimals must be <= decimals");
        ld2sdRate = 10 ** (decimals - _sharedDecimals);
    }

    /**
     *
     * public functions
     *
     */
    function circulatingSupply() public view virtual override returns (uint256) {
        return totalSupply();
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    /**
     *
     * internal functions
     *
     */
    function _debitFrom(address _from, uint16, bytes32, uint256 _amount) internal virtual override returns (uint256) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint256 _amount) internal virtual override returns (uint256) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    function _transferFrom(address _from, address _to, uint256 _amount) internal virtual override returns (uint256) {
        address spender = _msgSender();
        // if transfer from this contract, no need to check allowance
        if (_from != address(this) && _from != spender) _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return _amount;
    }

    function _ld2sdRate() internal view virtual override returns (uint256) {
        return ld2sdRate;
    }
}
