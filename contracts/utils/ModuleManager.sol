// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

// TODO move to a common file
/**
 * @title ModuleManager
 * @author TapiocaDAO
 * @notice Help to modularize a contract.
 *
 * @dev !!!!!!!! IMPORTANT !!!!!!!!
 * `_executeModule()` will sometimes return random/garbage data on the `(success, returnData) = module.delegatecall(_data)` call.
 *  Occurrence happens when calling a non view function on the main contract, that target a view function on the module.
 *  The module function is a view function that deals with `byte memory` slicing. Problem might be related to how Solidity handles memory bytes in 32 bytes chunks.
 */
abstract contract ModuleManager {
    /// @notice returns whitelisted modules
    mapping(uint8 module => address moduleAddress) internal _moduleAddresses;

    error ModuleManager__ModuleNotAuthorized();

    /**
     * @notice Sets a module to the whitelist.
     * @param _module The module to add.
     * @param _moduleAddress The module address.
     */
    function _setModule(uint8 _module, address _moduleAddress) internal {
        _moduleAddresses[_module] = _moduleAddress;
    }

    /**
     * @dev Returns the module address, if whitelisted.
     * @param _module The module we wants to execute.
     */
    function _extractModule(uint8 _module) internal view returns (address) {
        address module = _moduleAddresses[_module];
        if (module == address(0)) revert ModuleManager__ModuleNotAuthorized();

        return module;
    }

    /**
     * @notice Execute an call to a given module.
     *
     * @param _module The module to execute.
     * @param _data The data to execute.
     * @param _forwardRevert If true, forward the revert message from the module.
     *
     * @return returnData The return data from the module execution, if any.
     */
    function _executeModule(uint8 _module, bytes memory _data, bool _forwardRevert)
        internal
        returns (bytes memory returnData)
    {
        bool success = true;
        address module = _extractModule(_module);

        (success, returnData) = module.delegatecall(_data);
        if (!success && !_forwardRevert) {
            revert(_getRevertMsg(returnData));
        }
    }

    /**
     * @notice Return the revert message from an external call.
     * @param _returnData The return data from the external call.
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length > 1000) return "Module: reason too long";

        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Module: data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}
