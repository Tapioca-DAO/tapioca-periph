// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ITap} from "tapioca-periph/interfaces/oft/ITap.sol";
import {IPearlmit, PearlmitHandler} from "tapioca-periph/pearlmit/PearlmitHandler.sol";


contract TapiocaOptionsBrokerMock is PearlmitHandler {
    address public tapOFT;

    error TransferFailed();

    constructor(address _tapOft, IPearlmit _pearlmit) PearlmitHandler(_pearlmit) {
        tapOFT = _tapOft;
    }
    function getOTCDealDetails(uint256, address, uint256)
        external
        view
        returns (uint256 eligibleTapAmount, uint256 paymentTokenAmount, uint256 tapAmount)
    {
        return (1 ether, 1 ether, 1 ether);
    }
    function exerciseOption(uint256 _oTAPTokenID, address _paymentToken, uint256 _tapAmount) external {
        {
            bool isErr =
                pearlmit.transferFromERC20(msg.sender, address(this), _paymentToken, 1 ether);
            if (isErr) revert TransferFailed();
        }

        ITap(tapOFT).extractTAP(msg.sender, 1 ether);
    }
}