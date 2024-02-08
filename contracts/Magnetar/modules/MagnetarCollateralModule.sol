// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Tapioca
import {DepositAddCollateralAndBorrowFromMarketData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {MagnetarBaseModule} from "./MagnetarBaseModule.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/**
 * @title MagnetarCollateralModule
 * @author TapiocaDAO
 * @notice Magnetar collateral related operations
 */
contract MagnetarCollateralModule is MagnetarBaseModule {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /**
     * @notice helper for deposit to YieldBox, add collateral to a market, borrow from the same market and withdraw
     * @dev all operations are optional:
     *         - if `deposit` is false it will skip the deposit to YieldBox step
     *         - if `withdraw` is false it will skip the withdraw step
     *         - if `collateralAmount == 0` it will skip the add collateral step
     *         - if `borrowAmount == 0` it will skip the borrow step
     *     - the amount deposited to YieldBox is `collateralAmount`
     *
     * @param data.market the SGL/BigBang market
     * @param data.user the user to perform the action for
     * @param data.collateralAmount the collateral amount to add
     * @param data.borrowAmount the borrow amount
     * @param data.deposit true/false flag for the deposit to YieldBox step
     * @param data.withdrawParams necessary data for the same chain or the cross-chain withdrawal
     */
    function depositAddCollateralAndBorrowFromMarket(DepositAddCollateralAndBorrowFromMarketData memory data)
        public
        payable
    {
        // Check sender
        _checkSender(data.user);

        // Check
        if (!cluster.isWhitelisted(0, data.market)) {
            revert Magnetar_TargetNotWhitelisted(data.market);
        }

        IMarket market_ = IMarket(data.market);
        IYieldBox yieldBox_ = IYieldBox(market_.yieldBox());

        uint256 collateralId = market_.collateralId();
        (, address collateralAddress,,) = yieldBox_.assets(collateralId);

        uint256 _share = yieldBox_.toShare(collateralId, data.collateralAmount, false);
        // deposit to YieldBox
        if (data.deposit) {
            // transfers tokens from sender or from the user to this contract
            data.collateralAmount = _extractTokens(msg.sender, collateralAddress, data.collateralAmount);
            _share = yieldBox_.toShare(collateralId, data.collateralAmount, false);

            // deposit to YieldBox
            IERC20(collateralAddress).approve(address(yieldBox_), 0);
            IERC20(collateralAddress).approve(address(yieldBox_), data.collateralAmount);
            yieldBox_.depositAsset(collateralId, address(this), address(this), data.collateralAmount, 0);
        }

        // performs .addCollateral on data.market
        if (data.collateralAmount > 0) {
            _setApprovalForYieldBox(data.market, yieldBox_);
            market_.addCollateral(
                data.deposit ? address(this) : data.user, data.user, false, data.collateralAmount, _share
            );
        }

        // performs .borrow on data.market
        // if `withdraw` it uses `withdrawTo` to withdraw assets on the same chain or to another one
        if (data.borrowAmount > 0) {
            address borrowReceiver = data.withdrawParams.withdraw ? address(this) : data.user;
            market_.borrow(data.user, borrowReceiver, data.borrowAmount);

            if (data.withdrawParams.withdraw) {
                _withdrawToChain(data.withdrawParams);
            }
        }

        _revertYieldBoxApproval(data.market, yieldBox_);
    }
}
