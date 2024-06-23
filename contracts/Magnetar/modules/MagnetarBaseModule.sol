// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Tapioca
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {MagnetarWithdrawData} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IMarketHelper} from "tapioca-periph/interfaces/bar/IMarketHelper.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {Module, IMarket} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {SafeApprove} from "tapioca-periph/libraries/SafeApprove.sol";
import {ITOFT} from "tapioca-periph/interfaces/oft/ITOFT.sol";
import {MagnetarStorage} from "../MagnetarStorage.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract MagnetarBaseModule is MagnetarStorage {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeApprove for address;

    error Magnetar_GasMismatch(uint256 expected, uint256 received);
    error Magnetar_ExtractTokenFail();
    error Magnetar_UserMismatch();
    error Magnetar_MarketCallFailed(bytes call);
    error Magnetar_ActionParamsMismatch();
    error Magnetar_tOLPTokenMismatch();

    constructor(IPearlmit pearlmit, address _toeHelper) MagnetarStorage(pearlmit, _toeHelper) {}

    /// =====================
    /// Internal
    /// =====================
    function _withdrawHere(MagnetarWithdrawData memory data) internal {
        _checkWhitelisted(data.yieldBox);

        IYieldBox _yb = IYieldBox(data.yieldBox);

        if (data.extractFromSender) {
            // do NOT allow `extractFromSender` for whitelisted addresses
            //    because in this cases funds should be already here 
            //    since it comes from an internal flow
            if (cluster.isWhitelisted(0, msg.sender)) revert Magnetar_ExtractTokenFail();

            uint256 _share  = _yb.toShare(data.assetId, data.amount, false);
            _yb.transfer(msg.sender, address(this), data.assetId, _share);
        }
        
        if (data.unwrap) {
            _yb.withdraw(data.assetId, address(this), address(this), data.amount, 0);

            (, address assetAddress,,) = _yb.assets(data.assetId);
            ITOFT(assetAddress).unwrap(data.receiver, data.amount);
        } else {
            _yb.withdraw(data.assetId, address(this), data.receiver, data.amount, 0);
        }
    }

    function _setApprovalForYieldBox(address _target, IYieldBox _yieldBox) internal {
        bool isApproved = _yieldBox.isApprovedForAll(address(this), _target);
        if (!isApproved) {
            _yieldBox.setApprovalForAll(_target, true);
        }
    }

    function _revertYieldBoxApproval(address _target, IYieldBox _yieldBox) internal {
        bool isApproved = _yieldBox.isApprovedForAll(address(this), _target);
        if (isApproved) {
            _yieldBox.setApprovalForAll(_target, false);
        }
    }

    function _pearlmitApprove(address _yieldBox, uint256 _tokenId, address _market, uint256 _amount) internal {
        pearlmit.approve(1155, _yieldBox, _tokenId, _market, _amount.toUint200(), block.timestamp.toUint48());
    }

    function _extractTokens(address _from, address _token, uint256 _amount) internal returns (uint256) {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        // IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        bool isErr = pearlmit.transferFromERC20(_from, address(this), address(_token), _amount);
        if (isErr) revert Magnetar_ExtractTokenFail();
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        if (balanceAfter <= balanceBefore) revert Magnetar_ExtractTokenFail();
        return balanceAfter - balanceBefore;
    }

    function _depositToYb(IYieldBox _yieldBox, address _user, uint256 _tokenId, uint256 _amount) internal returns (uint256 amountOut, uint256 shareOut) {
        (, address assetAddress,,) = _yieldBox.assets(_tokenId);
        assetAddress.safeApprove(address(_yieldBox), _amount);
        (amountOut, shareOut) = _yieldBox.depositAsset(_tokenId, address(this), _user, _amount, 0);
        assetAddress.safeApprove(address(_yieldBox), 0);
    }

    function _marketRepay(IMarket _market, address _marketHelper, uint256 _amount, address _from, address _to)
        internal
        returns (uint256 repayed)
    {
        uint256 repayPart = helper.getBorrowPartForAmount(address(_market), _amount);
        (Module[] memory modules, bytes[] memory calls) =
            IMarketHelper(_marketHelper).repay(_from, _to, false, repayPart);

        (bool[] memory successes, bytes[] memory results) = _market.execute(modules, calls, true);
        if (!successes[0]) revert Magnetar_MarketCallFailed(calls[0]);

        repayed = IMarketHelper(_marketHelper).repayView(results[0]);
    }

    function _marketBorrow(IMarket _market, address _marketHelper, uint256 _amount, address _from, address _to)
        internal
    {
        (Module[] memory modules, bytes[] memory calls) = IMarketHelper(_marketHelper).borrow(_from, _to, _amount);

        (bool[] memory successes,) = _market.execute(modules, calls, true);
        if (!successes[0]) revert Magnetar_MarketCallFailed(calls[0]);
    }

    function _marketAddCollateral(
        IMarket _market,
        address _marketHelper,
        uint256 _collateralShare,
        address _from,
        address _to
    ) internal {
        (Module[] memory modules, bytes[] memory calls) =
            IMarketHelper(_marketHelper).addCollateral(_from, _to, false, 0, _collateralShare);
        (bool[] memory successes,) = _market.execute(modules, calls, true);
        if (!successes[0]) revert Magnetar_MarketCallFailed(calls[0]);
    }

    function _marketRemoveCollateral(
        IMarket _market,
        address _marketHelper,
        uint256 _collateralShare,
        address _from,
        address _to
    ) internal {
        (Module[] memory modules, bytes[] memory calls) =
            IMarketHelper(_marketHelper).removeCollateral(_from, _to, _collateralShare);
        (bool[] memory successes,) = _market.execute(modules, calls, true);
        if (!successes[0]) revert Magnetar_MarketCallFailed(calls[0]);
    }

    function _singularityAddAsset(ISingularity _singularity, uint256 _amount, address _from, address _to)
        internal
        returns (uint256 fraction)
    {
        IYieldBox _yieldBox = IYieldBox(_singularity._yieldBox());
        uint256 lendShare = _yieldBox.toShare(_singularity._assetId(), _amount, false);

        fraction = _singularity.addAsset(_from, _to, false, lendShare);
    }

    function _singularityRemoveAsset(ISingularity _singularity, uint256 _amount, address _from, address _to)
        internal
        returns (uint256 share)
    {
        _singularity.accrue();
        uint256 fraction = helper.getFractionForAmount(_singularity, _amount);
        share = _singularity.removeAsset(_from, _to, fraction);
    }

    function _tOBExit(address oTapAddress, address tOB, uint256 id) internal {
        IERC721(oTapAddress).approve(tOB, id);
        ITapiocaOptionBroker(tOB).exitPosition(id);
    }
}
