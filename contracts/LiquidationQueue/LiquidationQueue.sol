// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

import "../interfaces/IPenrose.sol";
import "../interfaces/ISingularity.sol";
import "../interfaces/ILiquidationQueue.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/interfaces/IStrategy.sol";
import "tapioca-sdk/dist/contracts/YieldBox/contracts/strategies/ERC20WithoutStrategy.sol";

import "tapioca-sdk/dist/contracts/YieldBox/contracts/YieldBox.sol";

/// @title LiquidationQueue
/// @author @0xRektora, TapiocaDAO
// TODO: Capital efficiency? (register assets to strategies) (farm strat for TAP)
// TODO: ERC20 impl?
contract LiquidationQueue is ILiquidationQueue {
    // ************ //
    // *** VARS *** //
    // ************ //
    /**
     * General information about the LiquidationQueue contract.
     */
    /// @notice returns metadata information
    LiquidationQueueMeta public liquidationQueueMeta;
    /// @notice targeted market
    ISingularity public singularity;
    /// @notice Penrose addres
    IPenrose public penrose;
    /// @notice YieldBox address
    YieldBox public yieldBox;

    /// @notice liquidation queue Penrose asset id
    uint256 public lqAssetId;
    /// @notice singularity asset id
    uint256 public marketAssetId;
    /// @notice asset that is being liquidated
    uint256 public liquidatedAssetId;

    /// @notice initialization status
    bool public onlyOnce;

    /**
     * Pools & order books information.
     */

    /// @notice Bid pools
    /// @dev x% premium => bid pool
    ///      0 ... 30 range
    ///      poolId => totalAmount
    ///      poolId => userAddress => userBidInfo.
    mapping(uint256 => PoolInfo) public bidPools;

    /// @notice The actual order book. Entries are stored only once a bid has been activated
    /// @dev poolId => bidIndex => bidEntry).
    mapping(uint256 => mapping(uint256 => OrderBookPoolEntry))
        public orderBookEntries;
    /// @notice Meta-data about the order book pool
    /// @dev poolId => poolInfo.
    mapping(uint256 => OrderBookPoolInfo) public orderBookInfos;

    /**
     * Ledger.
     */

    /// @notice User current bids
    /// @dev user => orderBookEntries[poolId][bidIndex]
    mapping(address => mapping(uint256 => uint256[])) public userBidIndexes;

    /// @notice Due balance of users
    /// @dev user => amountDue.
    mapping(address => uint256) public balancesDue;

    // ***************** //
    // *** CONSTANTS *** //
    // ***************** //
    uint256 constant MAX_BID_POOLS = 10; // Maximum amount of pools.
    // `amount` * ((`bidPool` * `PREMIUM_FACTOR`) / `PREMIUM_FACTOR_PRECISION`) = premium.
    uint256 constant PREMIUM_FACTOR = 100; // Premium factor.
    uint256 constant PREMIUM_FACTOR_PRECISION = 10_000; // Precision of the premium factor.

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 private constant WITHDRAWAL_FEE = 50; // 0.5%
    uint256 private constant WITHDRAWAL_FEE_PRECISION = 10_000;

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
    event Redeem(address indexed redeemer, address indexed to, uint256 amount);
    /// @notice event emitted when bid swapper is updated
    event BidSwapperUpdated(IBidder indexed _old, address indexed _new);
    /// @notice event emitted when usdo swapper is updated
    event UsdoSwapperUpdated(IBidder indexed _old, address indexed _new);

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //
    modifier Active() {
        require(onlyOnce, "LQ: Not initialized");
        _;
    }

    /// @notice Acts as a 'constructor', should be called by a Singularity market.
    /// @param  _liquidationQueueMeta Info about the liquidations.
    /// @param _singularity The Singularity market address
    function init(
        LiquidationQueueMeta calldata _liquidationQueueMeta,
        address _singularity
    ) external override {
        require(!onlyOnce, "LQ: Initialized");

        liquidationQueueMeta = _liquidationQueueMeta;

        singularity = ISingularity(_singularity);
        liquidatedAssetId = singularity.collateralId();
        marketAssetId = singularity.assetId();
        penrose = IPenrose(singularity.penrose());
        yieldBox = YieldBox(singularity.yieldBox());

        lqAssetId = marketAssetId;

        IERC20(singularity.asset()).approve(
            address(yieldBox),
            type(uint256).max
        );
        yieldBox.setApprovalForAll(address(singularity), true);

        // We initialize the pools to save gas on conditionals later on.
        for (uint256 i = 0; i <= MAX_BID_POOLS; ) {
            _initOrderBookPoolInfo(i);
            ++i;
        }

        onlyOnce = true; // We set the init flag.
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns targeted market
    /// @return market name
    function market() public view returns (string memory) {
        return singularity.name();
    }

    /// @notice returns order book size
    /// @param pool the pool id
    /// @return size order book size
    function getOrderBookSize(uint256 pool) public view returns (uint256 size) {
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        unchecked {
            size = poolInfo.nextBidPush - poolInfo.nextBidPull;
        }
    }

    /// @notice returns an array of 'OrderBookPoolEntry' for a pool
    /// @param pool the pool id
    /// return x order book pool entries details
    function getOrderBookPoolEntries(
        uint256 pool
    ) external view returns (OrderBookPoolEntry[] memory x) {
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        uint256 orderBookSize = poolInfo.nextBidPush - poolInfo.nextBidPull;

        x = new OrderBookPoolEntry[](orderBookSize); // Initialize the return array.

        mapping(uint256 => OrderBookPoolEntry)
            storage entries = orderBookEntries[pool];
        for (
            (uint256 i, uint256 j) = (poolInfo.nextBidPull, 0);
            i < poolInfo.nextBidPush;

        ) {
            x[j] = entries[i]; // Copy the entry to the return array.

            unchecked {
                ++i;
                ++j;
            }
        }
    }

    /// @notice Get the next not empty bid pool in ASC order.
    /// @return i The bid pool id.
    /// @return available True if there is at least 1 bid available across all the order books.
    /// @return totalAmount Total available liquidated asset amount.
    function getNextAvailBidPool()
        public
        view
        override
        returns (uint256 i, bool available, uint256 totalAmount)
    {
        for (; i <= MAX_BID_POOLS; ) {
            if (getOrderBookSize(i) != 0) {
                available = true;
                totalAmount = bidPools[i].totalAmount;
                break;
            }
            ++i;
        }
    }

    /// @notice returns user data for an existing bid pool
    /// @param pool the pool identifier
    /// @param user the user identifier
    /// @return bidder information
    function getBidPoolUserInfo(
        uint256 pool,
        address user
    ) external view returns (Bidder memory) {
        return bidPools[pool].users[user];
    }

    /// @notice returns number of pool bids for user
    /// @param user the user indentifier
    /// @param pool the pool identifier
    /// @return len user bids count
    function userBidIndexLength(
        address user,
        uint256 pool
    ) external view returns (uint256 len) {
        uint256[] memory bidIndexes = userBidIndexes[user][pool];

        uint256 bidIndexesLen = bidIndexes.length;
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        for (uint256 i = 0; i < bidIndexesLen; ) {
            if (bidIndexes[i] >= poolInfo.nextBidPull) {
                bidIndexesLen--;
            }
            unchecked {
                ++i;
            }
        }

        return bidIndexes.length;
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Add a bid to a bid pool using stablecoins.
    /// @dev Works the same way as `bid` but performs a swap from the stablecoin to USDO
    ///      - if stableAssetId == usdoAssetId, no swap is performed
    /// @param user The bidder
    /// @param pool To which pool the bid should go
    /// @param stableAssetId Stablecoin YieldBox asset id
    /// @param amountIn Stablecoin amount
    /// @param data Extra data for swap operations
    function bidWithStable(
        address user,
        uint256 pool,
        uint256 stableAssetId,
        uint256 amountIn,
        bytes calldata data
    ) external Active {
        require(pool <= MAX_BID_POOLS, "LQ: premium too high");
        require(
            address(liquidationQueueMeta.usdoSwapper) != address(0),
            "LQ: USDO swapper not set"
        );

        uint256 usdoAssetId = penrose.usdoAssetId();
        yieldBox.transfer(
            msg.sender,
            address(liquidationQueueMeta.usdoSwapper),
            stableAssetId,
            yieldBox.toShare(stableAssetId, amountIn, false)
        );

        uint256 usdoAmount = liquidationQueueMeta.usdoSwapper.swap(
            address(singularity),
            stableAssetId,
            amountIn,
            data
        );

        Bidder memory bidder = _bid(user, pool, usdoAmount, true);

        uint256 usdoValueInLqAsset = bidder.swapOnExecute
            ? liquidationQueueMeta.bidExecutionSwapper.getOutputAmount(
                address(singularity),
                usdoAssetId,
                usdoAmount,
                data
            )
            : bidder.usdoAmount;

        require(
            usdoValueInLqAsset >= liquidationQueueMeta.minBidAmount,
            "LQ: bid too low"
        );
    }

    /// @notice Add a bid to a bid pool.
    /// @dev Create an entry in `bidPools`.
    ///      Clean the userBidIndex here instead of the `executeBids()` function to save on gas.
    /// @param user The bidder.
    /// @param pool To which pool the bid should go.
    /// @param amount The amount in asset to bid.
    function bid(address user, uint256 pool, uint256 amount) external override Active {
        require(pool <= MAX_BID_POOLS, "LQ: premium too high");
        require(amount >= liquidationQueueMeta.minBidAmount, "LQ: bid too low");

        // Transfer assets to the LQ contract.
        uint256 assetId = lqAssetId;
        yieldBox.transfer(
            msg.sender,
            address(this),
            assetId,
            yieldBox.toShare(assetId, amount, false)
        );
        _bid(user, pool, amount, false);
    }

    /// @notice Activate a bid by putting it in the order book.
    /// @dev Create an entry in `orderBook` and remove it from `bidPools`.
    /// @dev Spam vector attack is mitigated the min amount req., 10min CD + activation fees.
    /// @param user The user to activate the bid for.
    /// @param pool The target pool.
    function activateBid(address user, uint256 pool) external override {
        Bidder memory bidder = bidPools[pool].users[user];

        require(bidder.timestamp > 0, "LQ: bid not available"); //fail early
        require(
            block.timestamp >=
                bidder.timestamp + liquidationQueueMeta.activationTime,
            "LQ: too soon"
        );

        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool]; // Info about the pool array indexes.

        // Create a new order book entry.
        OrderBookPoolEntry memory orderBookEntry;
        orderBookEntry.bidder = user;
        orderBookEntry.bidInfo = bidder;

        // Insert the order book entry and delete the bid entry from the given pool.
        orderBookEntries[pool][poolInfo.nextBidPush] = orderBookEntry;
        delete bidPools[pool].users[user];

        // Add the index to the user bid index.
        userBidIndexes[user][pool].push(poolInfo.nextBidPush);

        // Update the `orderBookInfos`.
        unchecked {
            ++poolInfo.nextBidPush;
        }
        orderBookInfos[pool] = poolInfo;

        uint256 bidAmount = orderBookEntry.bidInfo.isUsdo
            ? orderBookEntry.bidInfo.usdoAmount
            : orderBookEntry.bidInfo.liquidatedAssetAmount;
        uint256 assetValue = orderBookEntry.bidInfo.swapOnExecute
            ? liquidationQueueMeta.bidExecutionSwapper.getOutputAmount(
                address(singularity),
                penrose.usdoAssetId(),
                orderBookEntry.bidInfo.usdoAmount,
                ""
            )
            : bidAmount;
        bidPools[pool].totalAmount += assetValue;
        emit ActivateBid(
            msg.sender,
            user,
            pool,
            orderBookEntry.bidInfo.usdoAmount,
            orderBookEntry.bidInfo.liquidatedAssetAmount,
            assetValue,
            block.timestamp
        );
    }

    /// @notice Remove a not yet activated bid from the bid pool.
    /// @dev Remove `msg.sender` funds.
    /// @param user The user to send the funds to.
    /// @param pool The pool to remove the bid from.
    /// @return amountRemoved The amount of the bid.
    function removeBid(
        address user,
        uint256 pool
    ) external override returns (uint256 amountRemoved) {
        bool isUsdo = bidPools[pool].users[msg.sender].isUsdo;
        amountRemoved = isUsdo
            ? bidPools[pool].users[msg.sender].usdoAmount
            : bidPools[pool].users[msg.sender].liquidatedAssetAmount;
        require(amountRemoved > 0, "LQ: bid not available");
        delete bidPools[pool].users[msg.sender];

        uint256 lqAssetValue = amountRemoved;
        if (bidPools[pool].users[msg.sender].swapOnExecute) {
            lqAssetValue = liquidationQueueMeta
                .bidExecutionSwapper
                .getOutputAmount(
                    address(singularity),
                    penrose.usdoAssetId(),
                    amountRemoved,
                    ""
                );
        }
        require(
            lqAssetValue >= liquidationQueueMeta.minBidAmount,
            "LQ: bid does not exist"
        ); //save gas

        // Transfer assets
        uint256 assetId = isUsdo ? penrose.usdoAssetId() : lqAssetId;
        yieldBox.transfer(
            address(this),
            user,
            assetId,
            yieldBox.toShare(assetId, amountRemoved, false)
        );

        emit RemoveBid(
            msg.sender,
            user,
            pool,
            isUsdo ? amountRemoved : 0,
            isUsdo ? 0 : amountRemoved,
            lqAssetValue,
            block.timestamp
        );
    }

    /// @notice Redeem a balance.
    /// @dev `msg.sender` is used as the redeemer.
    /// @param to The address to redeem to.
    function redeem(address to) external override {
        require(balancesDue[msg.sender] > 0, "LQ: No balance due");

        uint256 balance = balancesDue[msg.sender];
        uint256 fee = (balance * WITHDRAWAL_FEE) / WITHDRAWAL_FEE_PRECISION;
        uint256 redeemable = balance - fee;

        balancesDue[msg.sender] = 0;
        balancesDue[liquidationQueueMeta.feeCollector] += fee;

        uint256 assetId = liquidatedAssetId;
        yieldBox.transfer(
            address(this),
            to,
            assetId,
            yieldBox.toShare(assetId, redeemable, false)
        );

        emit Redeem(msg.sender, to, redeemable);
    }

    /// @notice Execute the liquidation call by executing the bids placed in the pools in ASC order.
    /// @dev Should only be called from Singularity.
    ///      Singularity should send the `collateralAmountToLiquidate` to this contract before calling this function.
    /// Tx will fail if it can't transfer allowed Penrose asset from Singularity.
    /// @param collateralAmountToLiquidate The amount of collateral to liquidate.
    /// @param swapData Swap data necessary for swapping USDO to market asset; necessary only if bidder added USDO
    /// @return totalAmountExecuted The amount of asset that was executed.
    /// @return totalCollateralLiquidated The amount of collateral that was liquidated.
    function executeBids(
        uint256 collateralAmountToLiquidate,
        bytes calldata swapData
    )
        external
        override
        returns (uint256 totalAmountExecuted, uint256 totalCollateralLiquidated)
    {
        require(msg.sender == address(singularity), "LQ: Only Singularity");
        BidExecutionData memory data;

        (data.curPoolId, data.isBidAvail, ) = getNextAvailBidPool();
        data.exchangeRate = singularity.exchangeRate();
        // We loop through all the bids for each pools until all the collateral is liquidated
        // or no more bid are available.
        while (collateralAmountToLiquidate > 0 && data.isBidAvail) {
            data.poolInfo = orderBookInfos[data.curPoolId];
            // Reset pool vars.
            data.totalPoolAmountExecuted = 0;
            data.totalPoolCollateralLiquidated = 0;
            // While bid pool is not empty and we haven't liquidated enough collateral.
            while (
                collateralAmountToLiquidate > 0 &&
                data.poolInfo.nextBidPull != data.poolInfo.nextBidPush
            ) {
                // Get the next bid.
                data.orderBookEntry = orderBookEntries[data.curPoolId][
                    data.poolInfo.nextBidPull
                ];
                data.orderBookEntryCopy = data.orderBookEntry;

                // Get the total amount of asset with the pool discount applied for the bidder.
                data
                    .discountedBidderAmount = _viewBidderDiscountedCollateralAmount(
                    data.orderBookEntryCopy.bidInfo,
                    data.exchangeRate,
                    data.curPoolId
                );

                // Check if the bidder can pay the remaining collateral to liquidate `collateralAmountToLiquidate`.
                if (data.discountedBidderAmount > collateralAmountToLiquidate) {
                    (
                        uint256 finalDiscountedCollateralAmount,
                        uint256 finalUsdoAmount
                    ) = _userPartiallyBidAmount(
                            data.orderBookEntryCopy.bidInfo,
                            collateralAmountToLiquidate,
                            data.exchangeRate,
                            data.curPoolId,
                            swapData
                        );

                    // Execute the bid.
                    balancesDue[
                        data.orderBookEntryCopy.bidder
                    ] += collateralAmountToLiquidate; // Write balance.

                    if (!data.orderBookEntry.bidInfo.isUsdo) {
                        data
                            .orderBookEntry
                            .bidInfo
                            .liquidatedAssetAmount -= finalDiscountedCollateralAmount; // Update bid entry amount.
                    } else {
                        data
                            .orderBookEntry
                            .bidInfo
                            .usdoAmount -= finalUsdoAmount;
                    }

                    // Update the total amount executed, the total collateral liquidated and collateral to liquidate.
                    data
                        .totalPoolAmountExecuted += finalDiscountedCollateralAmount;
                    data
                        .totalPoolCollateralLiquidated += collateralAmountToLiquidate;
                    collateralAmountToLiquidate = 0; // Since we have liquidated all the collateral.
                    data.totalUsdoAmountUsed += finalUsdoAmount;

                    orderBookEntries[data.curPoolId][data.poolInfo.nextBidPull]
                        .bidInfo = data.orderBookEntry.bidInfo;
                } else {
                    (
                        uint256 finalCollateralAmount,
                        uint256 finalDiscountedCollateralAmount,
                        uint256 finalUsdoAmount
                    ) = _useEntireBidAmount(
                            data.orderBookEntryCopy.bidInfo,
                            data.discountedBidderAmount,
                            data.exchangeRate,
                            data.curPoolId,
                            swapData
                        );
                    // Execute the bid.
                    balancesDue[
                        data.orderBookEntryCopy.bidder
                    ] += finalDiscountedCollateralAmount; // Write balance.
                    data.orderBookEntry.bidInfo.usdoAmount = 0; // Update bid entry amount.
                    data.orderBookEntry.bidInfo.liquidatedAssetAmount = 0; // Update bid entry amount.
                    // Update the total amount executed, the total collateral liquidated and collateral to liquidate.
                    data.totalUsdoAmountUsed += finalUsdoAmount;
                    data.totalPoolAmountExecuted += finalCollateralAmount;
                    data
                        .totalPoolCollateralLiquidated += finalDiscountedCollateralAmount;

                    collateralAmountToLiquidate -= finalDiscountedCollateralAmount;
                    orderBookEntries[data.curPoolId][data.poolInfo.nextBidPull]
                        .bidInfo = data.orderBookEntry.bidInfo;
                    // Since the current bid was fulfilled, get the next one.
                    unchecked {
                        ++data.poolInfo.nextBidPull;
                    }
                }
            }
            // Update the totals.
            totalAmountExecuted += data.totalPoolAmountExecuted;
            totalCollateralLiquidated += data.totalPoolCollateralLiquidated;
            orderBookInfos[data.curPoolId] = data.poolInfo; // Update the pool info for the current pool.
            // Look up for the next available bid pool.
            (data.curPoolId, data.isBidAvail, ) = getNextAvailBidPool();
            bidPools[data.curPoolId].totalAmount -= totalAmountExecuted;

            emit ExecuteBids(
                msg.sender,
                data.curPoolId,
                data.totalUsdoAmountUsed,
                data.totalPoolAmountExecuted,
                data.totalPoolCollateralLiquidated,
                block.timestamp
            );
        }
        // Stack too deep
        {
            uint256 toSend = totalAmountExecuted;

            // Transfer the assets to the Singularity.
            yieldBox.withdraw(
                lqAssetId,
                address(this),
                address(this),
                toSend,
                0
            );
            yieldBox.depositAsset(
                marketAssetId,
                address(this),
                address(singularity),
                toSend,
                0
            );
        }
    }

    /// @notice updates the bid swapper address
    /// @param _swapper thew new ICollateralSwaper contract address
    function setBidExecutionSwapper(address _swapper) external override {
        require(msg.sender == address(singularity), "unauthorized");
        emit BidSwapperUpdated(
            liquidationQueueMeta.bidExecutionSwapper,
            _swapper
        );
        liquidationQueueMeta.bidExecutionSwapper = IBidder(_swapper);
    }

    /// @notice updates the bid swapper address
    /// @param _swapper thew new ICollateralSwaper contract address
    function setUsdoSwapper(address _swapper) external override {
        require(msg.sender == address(singularity), "unauthorized");
        emit UsdoSwapperUpdated(liquidationQueueMeta.usdoSwapper, _swapper);
        liquidationQueueMeta.usdoSwapper = IBidder(_swapper);
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _viewBidderDiscountedCollateralAmount(
        Bidder memory entry,
        uint256 exchangeRate,
        uint256 poolId
    ) private view returns (uint256) {
        uint256 bidAmount = entry.isUsdo
            ? entry.usdoAmount
            : entry.liquidatedAssetAmount;
        uint256 liquidatedAssetAmount = entry.swapOnExecute
            ? liquidationQueueMeta.bidExecutionSwapper.getOutputAmount(
                address(singularity),
                penrose.usdoAssetId(),
                entry.usdoAmount,
                ""
            )
            : bidAmount;
        return
            _getPremiumAmount(
                _bidToCollateral(liquidatedAssetAmount, exchangeRate),
                poolId,
                MODE.ADD
            );
    }

    function _useEntireBidAmount(
        Bidder memory entry,
        uint256 discountedBidderAmount,
        uint256 exchangeRate,
        uint256 poolId,
        bytes memory swapData
    )
        private
        returns (
            uint256 finalCollateralAmount,
            uint256 finalDiscountedCollateralAmount,
            uint256 finalUsdoAmount
        )
    {
        finalCollateralAmount = entry.liquidatedAssetAmount;
        finalDiscountedCollateralAmount = discountedBidderAmount;
        finalUsdoAmount = entry.usdoAmount;
        //Execute the swap if USDO was provided and it's different from the liqudation asset id
        if (entry.swapOnExecute) {
            yieldBox.transfer(
                address(this),
                address(liquidationQueueMeta.bidExecutionSwapper),
                penrose.usdoAssetId(),
                yieldBox.toShare(penrose.usdoAssetId(), entry.usdoAmount, false)
            );

            finalCollateralAmount = liquidationQueueMeta
                .bidExecutionSwapper
                .swap(
                    address(singularity),
                    penrose.usdoAssetId(),
                    entry.usdoAmount,
                    swapData
                );
            finalDiscountedCollateralAmount = _getPremiumAmount(
                _bidToCollateral(finalCollateralAmount, exchangeRate),
                poolId,
                MODE.ADD
            );
        }
    }

    function _userPartiallyBidAmount(
        Bidder memory entry,
        uint256 collateralAmountToLiquidate,
        uint256 exchangeRate,
        uint256 poolId,
        bytes memory swapData
    )
        private
        returns (
            uint256 finalDiscountedCollateralAmount,
            uint256 finalUsdoAmount
        )
    {
        finalUsdoAmount = 0;
        finalDiscountedCollateralAmount = _getPremiumAmount(
            _collateralToBid(collateralAmountToLiquidate, exchangeRate),
            poolId,
            MODE.SUB
        );

        //Execute the swap if USDO was provided and it's different from the liqudation asset id
        uint256 usdoAssetId = penrose.usdoAssetId();
        if (entry.swapOnExecute) {
            finalUsdoAmount = liquidationQueueMeta
                .bidExecutionSwapper
                .getInputAmount(
                    address(singularity),
                    usdoAssetId,
                    finalDiscountedCollateralAmount,
                    ""
                );

            yieldBox.transfer(
                address(this),
                address(liquidationQueueMeta.bidExecutionSwapper),
                usdoAssetId,
                yieldBox.toShare(usdoAssetId, finalUsdoAmount, false)
            );
            uint256 returnedCollateral = liquidationQueueMeta
                .bidExecutionSwapper
                .swap(
                    address(singularity),
                    usdoAssetId,
                    finalUsdoAmount,
                    swapData
                );
            require(
                returnedCollateral >= finalDiscountedCollateralAmount,
                "need-more-collateral"
            );
        }
    }

    function _bid(
        address user,
        uint256 pool,
        uint256 amount,
        bool isUsdo
    ) private returns (Bidder memory bidder) {
        bidder.usdoAmount = isUsdo ? amount : 0;
        bidder.liquidatedAssetAmount = isUsdo ? 0 : amount;
        bidder.timestamp = block.timestamp;
        bidder.isUsdo = isUsdo;
        bidder.swapOnExecute = isUsdo && lqAssetId != penrose.usdoAssetId();

        bidPools[pool].users[user] = bidder;

        emit Bid(
            msg.sender,
            user,
            pool,
            isUsdo ? amount : 0, //USDO amount
            isUsdo ? 0 : amount, //liquidated asset amount
            block.timestamp
        );

        // Clean the userBidIndex.
        uint256[] storage bidIndexes = userBidIndexes[user][pool];
        uint256 bidIndexesLen = bidIndexes.length;
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        for (uint256 i = 0; i < bidIndexesLen; ) {
            if (bidIndexes[i] >= poolInfo.nextBidPull) {
                bidIndexesLen = bidIndexes.length;
                bidIndexes[i] = bidIndexes[bidIndexesLen - 1];
                bidIndexes.pop();
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Called with `init`, setup the initial pool info values.
    /// @param pool The targeted pool.
    function _initOrderBookPoolInfo(uint256 pool) internal {
        OrderBookPoolInfo memory poolInfo;
        poolInfo.poolId = uint32(pool);
        orderBookInfos[pool] = poolInfo;
    }

    /// @notice Get the discount gained from a bid in a `poolId` given a `amount`.
    /// @param amount The amount of collateral to get the discount from.
    /// @param poolId The targeted pool.
    /// @param mode 0 subtract - 1 add.
    function _getPremiumAmount(
        uint256 amount,
        uint256 poolId,
        MODE mode
    ) internal pure returns (uint256) {
        uint256 premium = (amount * poolId * PREMIUM_FACTOR) /
            PREMIUM_FACTOR_PRECISION;
        return mode == MODE.ADD ? amount + premium : amount - premium;
    }

    /// @notice Convert a bid amount to a collateral amount.
    /// @param amount The amount of bid to convert.
    /// @param exchangeRate The exchange rate to use.
    function _bidToCollateral(
        uint256 amount,
        uint256 exchangeRate
    ) internal pure returns (uint256) {
        return (amount * exchangeRate) / EXCHANGE_RATE_PRECISION;
    }

    /// @notice Convert a collateral amount to a bid amount.
    /// @param collateralAmount The amount of collateral to convert.
    /// @param exchangeRate The exchange rate to use.
    function _collateralToBid(
        uint256 collateralAmount,
        uint256 exchangeRate
    ) internal pure returns (uint256) {
        return (collateralAmount * EXCHANGE_RATE_PRECISION) / exchangeRate;
    }
}
