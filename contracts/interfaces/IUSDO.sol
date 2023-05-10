// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IUSDOBase {
    struct IApproval {
        bool allowFailure;
        address target;
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct ILendParams {
        uint256 amount;
        address marketHelper;
        address market;
    }

    struct ISendOptions {
        uint256 extraGasLimit;
        address zroPaymentAddress;
    }

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function sendToYBAndLend(
        address _from,
        address _to,
        uint16 lzDstChainId,
        ILendParams calldata lendParams,
        ISendOptions calldata options,
        IApproval[] calldata approvals
    ) external payable;
}

interface IUSDO is IUSDOBase, IERC20Metadata {}
