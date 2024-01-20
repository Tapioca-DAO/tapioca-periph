// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

interface IStargateFeeLibrary {
    struct SwapObj {
        uint256 amount;
        uint256 eqFee;
        uint256 eqReward;
        uint256 lpFee;
        uint256 protocolFee;
        uint256 lkbRemove;
    }

    function getFees(uint256 _srcPoolId, uint256 _dstPoolId, uint16 _dstChainId, address _from, uint256 _amountSD)
        external
        view
        returns (SwapObj memory s);

    function getVersion() external pure returns (string memory);
}
