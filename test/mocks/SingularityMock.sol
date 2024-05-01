// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPenrose} from "tapioca-periph/interfaces/bar/IPenrose.sol";
import {Module} from "tapioca-periph/interfaces/bar/IMarket.sol";

contract SingularityMock is EIP712 {
    using SafeERC20 for IERC20;

    IPenrose public penrose;
    IYieldBox public _yieldBox;
    uint256 public _collateralId;
    uint256 public _assetId;
    IERC20 public _collateral;
    IERC20 public _asset;

    /// @notice total collateral supplied
    uint256 public _totalCollateralShare;
    /// @notice borrow amount per user
    mapping(address => uint256) public _userBorrowPart;
    /// @notice collateral share per user
    mapping(address => uint256) public _userCollateralShare;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant _PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // keccak256("PermitBorrow(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 private constant _PERMIT_TYPEHASH_BORROW =
        0xe9685ff6d48c617fe4f692c50e602cce27cbad0290beb93cfa77eac43968d58c;

    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowanceBorrow;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) private _nonces;

    error SingularityMock_TooMuch();
    error SingularityMock_ModuleNotSet();
    error SingularityMock_NotValid();

    constructor(address yieldBox, uint256 collateralId, uint256 assetId, address collateral, address asset, address _penrose)
        EIP712("Tapioca Singularity", "1")
    {
        _yieldBox = IYieldBox(yieldBox);
        _collateralId = collateralId;
        _assetId = assetId;
        _collateral = IERC20(collateral);
        _asset = IERC20(asset);
        penrose = IPenrose(_penrose);
    }

    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner];
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveBorrow(address spender, uint256 amount) external returns (bool) {
        _approveBorrow(msg.sender, spender, amount);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        _permit(true, owner, spender, value, deadline, v, r, s);
    }

    function permitBorrow(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        _permit(false, owner, spender, value, deadline, v, r, s);
    }

    function borrow(address from, address to, uint256 amount) external returns (uint256 part, uint256 share) {
        if (amount == 0) return (0, 0);

        _userBorrowPart[from] += amount;

        share = _yieldBox.toShare(_assetId, amount, true);

        _yieldBox.transfer(address(this), to, _assetId, share);
    }

    function addCollateral(address from, address to, bool skim, uint256 amount, uint256 share) external {
        if (share == 0) {
            share = _yieldBox.toShare(_collateralId, amount, false);
        }

        uint256 oldTotalCollateralShare = _totalCollateralShare;
        _userCollateralShare[to] += share;
        _totalCollateralShare = oldTotalCollateralShare + share;

        _addTokens(from, to, _collateralId, share, oldTotalCollateralShare, skim);
    }

    function removeCollateral(address, address to, uint256 share) external {
        _yieldBox.transfer(address(this), to, _collateralId, share);
    }

    struct _BuyCollateralCalldata {
        address from;
        uint256 borrowAmount;
        uint256 supplyAmount;
        bytes data;
    }

    function buyCollateral(address from, uint256 borrowAmount, uint256 supplyAmount, bytes calldata data)
        public
        returns (uint256 amountOut)
    {
        // Stack too deep fix
        _BuyCollateralCalldata memory calldata_;
        {
            calldata_.from = from;
            calldata_.borrowAmount = borrowAmount;
            calldata_.supplyAmount = supplyAmount;
            calldata_.data = data;
        }

        // Let this fail first to save gas:
        uint256 supplyShare = _yieldBox.toShare(_assetId, calldata_.supplyAmount, true);
        uint256 supplyShareToAmount;
        if (supplyShare > 0) {
            (supplyShareToAmount,) = _yieldBox.withdraw(_assetId, calldata_.from, address(this), 0, supplyShare);
        }

        _userBorrowPart[from] += calldata_.borrowAmount;

        (uint256 borrowShareToAmount,) =
            _yieldBox.withdraw(_assetId, address(this), address(this), calldata_.borrowAmount, 0);

        //swap 1:1
        uint256 collateralAmount = borrowShareToAmount;

        // @dev !Contract needs to be prefunded with the right amount of collateral!
        // _yieldBox.depositAsset(_collateralId, address(this), address(this), collateralAmount, 0);

        uint256 collateralShare = _yieldBox.toShare(_collateralId, collateralAmount, false);

        uint256 oldTotalCollateralShare = _totalCollateralShare;
        _userCollateralShare[from] += collateralShare;
        _totalCollateralShare = oldTotalCollateralShare + collateralShare;

        _addTokens(address(this), from, _collateralId, collateralShare, oldTotalCollateralShare, false);

        return collateralAmount;
    }

    function _addTokens(address from, address, uint256 assetId, uint256 share, uint256 total, bool skim) internal {
        if (skim) {
            if (share > _yieldBox.balanceOf(address(this), assetId) - total) {
                revert SingularityMock_TooMuch();
            }
        } else {
            _yieldBox.transfer(from, address(this), assetId, share);
        }
    }

    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner]++;
    }

    function _permit(
        bool asset, // 1 = asset, 0 = collateral
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash;

        structHash = keccak256(
            abi.encode(
                asset ? _PERMIT_TYPEHASH : _PERMIT_TYPEHASH_BORROW, owner, spender, value, _useNonce(owner), deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);

        require(signer == owner, "ERC20Permit: invalid signature");

        if (asset) {
            _approve(owner, spender, value);
        } else {
            _approveBorrow(owner, spender, value);
        }
    }

    function _approveBorrow(address owner, address spender, uint256 amount) internal {
        allowanceBorrow[owner][spender] = amount;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        allowance[owner][spender] = amount;
    }

    function execute(Module[] calldata modules, bytes[] calldata calls, bool revertOnFail)
        external
        returns (bool[] memory successes, bytes[] memory results)
    {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        if (modules.length != calls.length) revert SingularityMock_NotValid();
        unchecked {
            for (uint256 i; i < calls.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(calls[i]);

                if (!success && revertOnFail) {
                    revert(abi.decode(_getRevertMsg(result), (string)));
                }
                successes[i] = success;
                results[i] = !success ? _getRevertMsg(result) : result;
            }
        }
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (bytes memory) {
        if (_returnData.length > 1000) return "Market: reason too long";
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Market: no return data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return _returnData; // All that remains is the revert string
    }
}
