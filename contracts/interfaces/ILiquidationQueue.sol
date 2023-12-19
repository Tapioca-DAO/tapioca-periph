// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IBidder.sol";

interface ILiquidationQueue {
    enum MODE {
        ADD,
        SUB
    }

    struct PoolInfo {
        uint256 totalAmount; //liquidated asset amount
        mapping(address => Bidder) users;
    }
    struct Bidder {
        bool isUsdo;
        bool swapOnExecute;
        uint256 usdoAmount;
        uint256 liquidatedAssetAmount;
        uint256 timestamp; // Timestamp in second of the last bid.
    }

    struct OrderBookPoolEntry {
        address bidder;
        Bidder bidInfo;
    }

    struct OrderBookPoolInfo {
        uint32 poolId;
        uint32 nextBidPull; // Next position in `entries` to start pulling bids from
        uint32 nextBidPush; // Next position in `entries` to start pushing bids to
    }

    struct LiquidationQueueMeta {
        uint256 activationTime; // Time needed before a bid can be activated for execution
        uint256 minBidAmount; // Minimum bid amount
        address feeCollector; // Address of the fee collector
        IBidder bidExecutionSwapper; //Allows swapping USDO to collateral when a bid is executed
        IBidder usdoSwapper; //Allows swapping any other stablecoin to USDO
    }

    struct BidExecutionData {
        uint256 curPoolId;
        bool isBidAvail;
        OrderBookPoolInfo poolInfo;
        OrderBookPoolEntry orderBookEntry;
        OrderBookPoolEntry orderBookEntryCopy;
        uint256 totalPoolAmountExecuted;
        uint256 totalPoolCollateralLiquidated;
        uint256 totalUsdoAmountUsed;
        uint256 exchangeRate;
        uint256 discountedBidderAmount;
    }

    // ************** //
    // *** EVENTS *** //
    // ************** //
    /// @notice event emitted when a bid is placed
    event Bid(
        address indexed caller,
        address indexed bidder,
        uint256 indexed pool,
        uint256 usdoAmount,
        uint256 liquidatedAssetAmount,
        uint256 timestamp
    );
    /// @notice event emitted when a bid is activated
    event ActivateBid(
        address indexed caller,
        address indexed bidder,
        uint256 indexed pool,
        uint256 usdoAmount,
        uint256 liquidatedAssetAmount,
        uint256 collateralValue,
        uint256 timestamp
    );
    /// @notice event emitted a bid is removed
    event RemoveBid(
        address indexed caller,
        address indexed bidder,
        uint256 indexed pool,
        uint256 usdoAmount,
        uint256 liquidatedAssetAmount,
        uint256 collateralValue,
        uint256 timestamp
    );
    /// @notice event emitted when bids are executed
    event ExecuteBids(
        address indexed caller,
        uint256 indexed pool,
        uint256 usdoAmountExecuted,
        uint256 liquidatedAssetAmountExecuted,
        uint256 collateralLiquidated,
        uint256 timestamp
    );
    /// @notice event emitted when funds are redeemed
    event Redeem(
        address indexed redeemer,
        address indexed to,
        uint256 indexed amount
    );
    /// @notice event emitted when bid swapper is updated
    event BidSwapperUpdated(IBidder indexed _old, address indexed _new);
    /// @notice event emitted when usdo swapper is updated
    event UsdoSwapperUpdated(IBidder indexed _old, address indexed _new);

    function lqAssetId() external view returns (uint256);

    function marketAssetId() external view returns (uint256);

    function liquidatedAssetId() external view returns (uint256);

    function init(LiquidationQueueMeta calldata, address singularity) external;

    function market() external view returns (string memory);

    function getOrderBookSize(
        uint256 pool
    ) external view returns (uint256 size);

    function getOrderBookPoolEntries(
        uint256 pool
    ) external view returns (OrderBookPoolEntry[] memory x);

    function getBidPoolUserInfo(
        uint256 pool,
        address user
    ) external view returns (Bidder memory);

    function userBidIndexLength(
        address user,
        uint256 pool
    ) external view returns (uint256 len);

    function onlyOnce() external view returns (bool);

    function setBidExecutionSwapper(address swapper) external;

    function setUsdoSwapper(address swapper) external;

    function getNextAvailBidPool()
        external
        view
        returns (uint256 i, bool available, uint256 totalAmount);

    function bidWithStable(
        address user,
        uint256 pool,
        uint256 stableAssetId,
        uint256 amountIn,
        bytes calldata data
    ) external;

    function bid(address user, uint256 pool, uint256 amount) external;

    function activateBid(address user, uint256 pool) external;

    function removeBid(
        address user,
        uint256 pool
    ) external returns (uint256 amountRemoved);

    function redeem(address to) external;

    function executeBids(
        uint256 collateralAmountToLiquidate,
        bytes calldata swapData
    ) external returns (uint256 amountExecuted, uint256 collateralLiquidated);
}
