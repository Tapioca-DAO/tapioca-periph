// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ICluster.sol";

contract Cluster is Ownable, ICluster {
    // ************ //
    // *** VARS *** //
    // ************ //

    /// @notice returns the current LayerZero chain id
    uint16 public lzChainId;
    /// @notice returns true if an address is marked as an Editor
    /// @dev editors can update contracts' whitelist status
    mapping(address editor => bool status) public isEditor;
    /// @notice returns the whitelist status for an address
    /// @dev whitelist type => LZ chain id => contract => status
    mapping(ICluster.WhitelistType whitelistType => mapping(uint16 lzChainId => mapping(address _contract => bool status)))
        private _whitelisted;

    /// @notice event emitted when LZ chain id is updated
    event LzChainUpdate(uint256 _oldChain, uint256 _newChain);
    /// @notice event emitted when an editor status is updated
    event EditorUpdated(
        address indexed _editor,
        bool _oldStatus,
        bool _newStatus
    );
    /// @notice event emitted when a contract status is updated
    event ContractUpdated(
        address indexed _contract,
        uint16 indexed _lzChainId,
        ICluster.WhitelistType _type,
        bool _oldStatus,
        bool _newStatus
    );

    constructor(uint16 _lzChainId) {
        lzChainId = _lzChainId;
    }

    // ******************** //
    // *** VIEW METHODS *** //
    // ******************** //
    /// @notice returns the whitelist status of a contract
    /// @param _whitelistType the contract's type
    /// @param _lzChainId LayerZero chain id
    /// @param _addr the contract's address
    function isWhitelisted(
        ICluster.WhitelistType _whitelistType,
        uint16 _lzChainId,
        address _addr
    ) external view override returns (bool) {
        return _whitelisted[_whitelistType][_lzChainId][_addr];
    }

    // ********************** //
    // *** PUBLIC METHODS *** //
    // ********************** //
    /// @notice updates the whitelist status of a contract
    /// @dev can only be called by Editors or the Owner
    /// @param _whitelistType the contract's type
    /// @param _lzChainId LayerZero chain id
    /// @param _addr the contract's address
    /// @param _status the new whitelist status
    function updateContract(
        ICluster.WhitelistType _whitelistType,
        uint16 _lzChainId,
        address _addr,
        bool _status
    ) external override {
        require(
            isEditor[msg.sender] || msg.sender == owner(),
            "Cluster: not authorized"
        );

        if (_lzChainId == 0) {
            //set lz chain as the current one
            _lzChainId = lzChainId;
        }

        emit ContractUpdated(
            _addr,
            _lzChainId,
            _whitelistType,
            _whitelisted[_whitelistType][_lzChainId][_addr],
            _status
        );
        _whitelisted[_whitelistType][_lzChainId][_addr] = _status;
    }

    // ********************* //
    // *** OWNER METHODS *** //
    // ********************* //
    /// @notice updates LayerZero chain id
    /// @param _lzChainId the new LayerZero chain id
    function updateLzChain(uint16 _lzChainId) external onlyOwner {
        emit LzChainUpdate(lzChainId, _lzChainId);
        lzChainId = _lzChainId;
    }

    /// @notice updates the editor status
    /// @param _editor the editor's address
    /// @param _status the new editor's status
    function updateEditor(address _editor, bool _status) external onlyOwner {
        emit EditorUpdated(_editor, isEditor[_editor], _status);
        isEditor[_editor] = _status;
    }
}