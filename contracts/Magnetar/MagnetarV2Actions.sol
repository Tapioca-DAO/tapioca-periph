// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

abstract contract MagnetarV2Actions {
    uint16 internal constant PERMIT_ALL = 1;
    uint16 internal constant PERMIT = 2;

    uint16 internal constant YB_DEPOSIT_ASSET = 100;
    uint16 internal constant YB_WITHDRAW_ASSET = 101;

    uint16 internal constant MARKET_ADD_COLLATERAL = 200;
    uint16 internal constant MARKET_BORROW = 201;
    uint16 internal constant MARKET_WITHDRAW_TO = 202;
    uint16 internal constant MARKET_LEND = 203;
    uint16 internal constant MARKET_REPAY = 204;
    uint16 internal constant MARKET_YBDEPOSIT_AND_LEND = 205;
    uint16 internal constant MARKET_YBDEPOSIT_COLLATERAL_AND_BORROW = 206;

    uint16 internal constant TOFT_WRAP = 300;
    uint16 internal constant TOFT_SEND_FROM = 301;
    uint16 internal constant TOFT_SEND_APPROVAL = 302;
    uint16 internal constant TOFT_SEND_AND_BORROW = 303;
    uint16 internal constant TOFT_SEND_AND_LEND = 304;
}
