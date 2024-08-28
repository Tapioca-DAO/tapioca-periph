// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

abstract contract PearlmitHandler is Ownable {
    // ************ //
    // *** VARS *** //
    // ************ //

    IPearlmit public pearlmit;

    // ************** //
    // *** EVENTS *** //
    // ************** //

    event PearlmitUpdated(IPearlmit oldPearlmit, IPearlmit newPearlmit);

    // ***************** //
    // *** CONSTRUCTOR *** //
    // ***************** //

    constructor(IPearlmit _pearlmit) {
        emit PearlmitUpdated(pearlmit, _pearlmit);
        pearlmit = _pearlmit;
    }

    /// @notice Perform an allowance check for an ERC721 token on Pearlmit.
    function isERC721Approved(address owner, address spender, address token, uint256 id) internal view returns (bool) {
        (uint256 allowedAmount,) = pearlmit.allowance(owner, spender, 721, token, id); // Returns 0 if not approved or expired
        return allowedAmount > 0;
    }

    /// @notice Perform an allowance check for an ERC20 token on Pearlmit.
    function isERC20Approved(address owner, address spender, address token, uint256 amount)
        internal
        view
        returns (bool)
    {
        (uint256 allowedAmount,) = pearlmit.allowance(owner, spender, 20, token, 0); // Returns 0 if not approved or expired
        return allowedAmount >= amount;
    }

    // ******************* //
    // *** OWNER METHODS *** //
    // ******************* //

    /**
     * @notice updates the Pearlmit address.
     * @dev can only be called by the owner.
     * @param _pearlmit the new address.
     */
    function setPearlmit(IPearlmit _pearlmit) external onlyOwner {
        emit PearlmitUpdated(pearlmit, _pearlmit);
        pearlmit = _pearlmit;
    }
}
