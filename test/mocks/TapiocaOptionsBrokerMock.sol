// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {ITap} from "tapioca-periph/interfaces/oft/ITap.sol";
import {IPearlmit, PearlmitHandler} from "tapioca-periph/pearlmit/PearlmitHandler.sol";

import {ERC721Mock} from "./ERC721Mock.sol";

contract TapiocaOptionsBrokerMock is PearlmitHandler {
    address public tapOFT;
    address public oTAP;
    address public tOLP;

    error TransferFailed();

    constructor(address _otap, address _tapOft, IPearlmit _pearlmit) PearlmitHandler(_pearlmit) {
        tapOFT = _tapOft;
        oTAP = _otap;
    }

    function setTOLP(address _a) external {
        tOLP = _a;
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
            bool isErr = pearlmit.transferFromERC20(msg.sender, address(this), _paymentToken, 1 ether);
            if (isErr) revert TransferFailed();
        }

        ITap(tapOFT).extractTAP(msg.sender, 1 ether);
    }

    function participate(uint256 _tOLPTokenID) external returns (uint256 oTAPTokenID) {
        {
            bool isErr = pearlmit.transferFromERC721(msg.sender, address(this), tOLP, _tOLPTokenID);
            if (isErr) revert TransferFailed();
        }

        ERC721Mock(oTAP).mint(msg.sender, 1);
        return 1;
    }


}
