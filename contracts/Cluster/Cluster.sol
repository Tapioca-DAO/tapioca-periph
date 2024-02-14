// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract Cluster is Ownable, ICluster {
    // ************ //
    // *** VARS *** //
    // ************ //

    /// @notice returns the current LayerZero chain id
    uint32 public lzChainId;

    /// @notice returns the whitelist status for an address
    /// @dev LZ chain id => contract => status
    mapping(uint32 lzChainId => mapping(address _contract => bool status)) private _whitelisted;

    /// @notice Centralized role assignment for Tapioca contract. Other contracts can use this mapping to check if an address has a role on them
    mapping(address _contract => mapping(bytes32 role => mapping(address target => bool hasRole))) public hasRole;

    /// @notice event emitted when LZ chain id is updated
    event LzChainUpdate(uint256 indexed _oldChain, uint256 indexed _newChain);
    /// @notice event emitted when an editor status is updated
    event EditorUpdated(address indexed _editor, bool indexed _oldStatus, bool indexed _newStatus);
    /// @notice event emitted when a contract status is updated
    event ContractUpdated(
        address indexed _contract, uint32 indexed _lzChainId, bool indexed _oldStatus, bool _newStatus
    );
    /// @notice event emitted when a role is set
    event RoleSet(address indexed _contract, bytes32 indexed _role, address indexed _target, bool _hasRole);

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error NotAuthorized();

    constructor(uint32 _lzChainId, address _owner) {
        lzChainId = _lzChainId;
        transferOwnership(_owner);
    }

    modifier isAuthorized() {
        if (msg.sender != owner()) {
            revert NotAuthorized();
        }
        _;
    }

    // ******************** //
    // *** VIEW METHODS *** //
    // ******************** //
    /// @notice returns the whitelist status of a contract
    /// @param _lzChainId LayerZero chain id
    /// @param _addr the contract's address
    function isWhitelisted(uint32 _lzChainId, address _addr) external view override returns (bool) {
        if (_lzChainId == 0) {
            _lzChainId = lzChainId;
        }
        return _whitelisted[_lzChainId][_addr];
    }

    // ********************** //
    // *** PUBLIC METHODS *** //
    // ********************** //

    /// @notice updates the whitelist status of contracts
    /// @dev can only be called by Editors or the Owner
    /// @param _lzChainId LayerZero chain id
    /// @param _addresses the contracts addresses
    /// @param _status the new whitelist status
    function batchUpdateContracts(uint32 _lzChainId, address[] memory _addresses, bool _status)
        external
        override
        isAuthorized
    {
        if (_lzChainId == 0) {
            //set lz chain as the current one
            _lzChainId = lzChainId;
        }

        for (uint256 i; i < _addresses.length; i++) {
            emit ContractUpdated(_addresses[i], _lzChainId, _whitelisted[_lzChainId][_addresses[i]], _status);
            _whitelisted[_lzChainId][_addresses[i]] = _status;
        }
    }

    /// @notice updates the whitelist status of a contract
    /// @dev can only be called by Editors or the Owner
    /// @param _lzChainId LayerZero chain id
    /// @param _addr the contract's address
    /// @param _status the new whitelist status
    function updateContract(uint32 _lzChainId, address _addr, bool _status) external override isAuthorized {
        if (_lzChainId == 0) {
            //set lz chain as the current one
            _lzChainId = lzChainId;
        }

        emit ContractUpdated(_addr, _lzChainId, _whitelisted[_lzChainId][_addr], _status);
        _whitelisted[_lzChainId][_addr] = _status;
    }

    /**
     * @notice sets a role for a contract.
     * @param _contract the contract's address.
     * @param _role the role's name for the contract, in bytes32 format.
     * @param _target the address to set the role for.
     * @param _hasRole the new role status.
     */
    function setRoleForContract(address _contract, bytes32 _role, address _target, bool _hasRole)
        external
        isAuthorized
    {
        hasRole[_contract][_role][_target] = _hasRole;
        emit RoleSet(_contract, _role, _target, _hasRole);
    }

    // ********************* //
    // *** OWNER METHODS *** //
    // ********************* //

    /// @notice updates LayerZero chain id
    /// @param _lzChainId the new LayerZero chain id
    function updateLzChain(uint32 _lzChainId) external onlyOwner {
        emit LzChainUpdate(lzChainId, _lzChainId);
        lzChainId = _lzChainId;
    }
}
