// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ITapiocaOracle} from "tap-utils/interfaces/periph/ITapiocaOracle.sol";

contract OracleMock is ITapiocaOracle {
    uint256 public rate;
    bool public success;
    string public __name;
    string public __symbol;

    constructor(string memory _name, string memory _symbol, uint256 _rate) {
        success = true;
        rate = _rate;
        __name = _name;
        __symbol = _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function set(uint256 rate_) public {
        // The rate can be updated.
        rate = rate_;
    }

    function setSuccess(bool val) public {
        success = val;
    }

    function getDataParameter() public pure returns (bytes memory) {
        return abi.encode("0x0");
    }

    // Get the latest exchange rate
    function get(bytes calldata) public view returns (bool, uint256) {
        return (success, rate);
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata) public view returns (bool, uint256) {
        return (success, rate);
    }

    function peekSpot(bytes calldata) public view returns (uint256) {
        return rate;
    }

    function name(bytes calldata) public view returns (string memory) {
        return __name;
    }

    function symbol(bytes calldata) public view returns (string memory) {
        return __symbol;
    }
}
