// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/*
                                  ,,,,,          ,,,,,,,,
                       ,▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄ç   └▓▓M▒▒▒▒▒▒▒▒▒▒▒░░▒╦,
                   ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄  └%▒▒▒▒▒▒▒▒░░░░░░▒▒▒╤
                 ╓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓φ            `╚▒▒▒▒▒M
               ,▓▓▓▓▓▓▓▓▓▓▀"'       └"▀▓▓▓▓▓▓▓▓▓▓▄            `▒▒▒▒▒@
              ▄▓▓▓▓▓▓▓▓▀`               "▀▓▓▓▓▓▓▓▓▓▄           ▒▒▒▒▒▓
             ▄▓▓▓▓▓▓▓▀                    └█▓▓▓▓▓▓▓▓▓▄        á▒▒▒M▓Ñ
            ▄▓▓▓▓▓▓▓▀                      `█▓▓▓▓▓▓█▓█▄╖╖╖φ@▓▒▒▓▓▓▀
           ┌▓▓▓▓▓▓▓▀                        └▓▓▓▓▓▓∩▀█▓▓█▓▒▒▒▒▓▓▓▀`
           ▄▓▓▓▓▓▓▓                          ▀▓▓▓▓▓∩ `▀▓▓▓█▓▒▓▓`
           ▓▓▓▓▓▓▓▌                          ▐▓▓▓▓▓∩   └▀▓███▓▓▓
           ▓▓▓▓▓▓▓▌                          ▐▓▓▓██∩     ╙█████▓▓µ
           ▓▓▓▓▓▓▓▌                          ▐█████∩       ▀█████▓M
           ▀▓▓▓▓▓▓▓                          ▐▀▀▀▀▀∩        `▀▀▀▀▀▀▓u
           ▐▓▓▓▓▓▓▓▄                        ┌▄▄▄▄  ╖╖╖╖,       ╓,╓╓÷
            ▀▓▓▓▓▓▓▓▄                       ▐████   %▒▒▒@    .▒░▒▒∩
             ▀███████▄                    ,▓▐████    └╬▒▒▒U ╓░▒▒╝
              ▀████████▄                ,▄██▐████      ╙▒░░▒▒▒▒∩
               ▀█████████▓▄,         ,▄▓████▐████       `▒▒▒▒▒
                 ▀████████████▓▓▓▓▓█████████▐████      ╓▒▒▒▒▒▒▓µ
                   ╙▀███████████████████████▐████    ,▒▒▒▒∩ ╚▒▓▓▓
                      "▀▀███████████████▀▀╙ ▐████   ╗▒▒▒╝    `▓▓▓▓φ
                           ``"▀▀▀▀▀╙"`      └▀▀▀▀  """╙`       "╙"""

                        ███████ ORVIX Labs ███████

  🔹 OrvixAggregator.sol

  🔹 BNB Chain AMM V2 Traversal Router

  🔹 Multi-factory AMM V2 routing infrastructure
     for deterministic path discovery, quoting,
     and swap execution across supported
     liquidity sources on BNB Chain.

  🔹 Designed for wallet, dApp, and infrastructure integrations.
  🔹 Copyright (c) 2026 ORVIX Labs
  🔹 Licensed under MIT.
  🔹 https://orvix.io

*/

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// INTERFACES

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IWrappedNative {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

// MATH LIBRARIES

/// @title FullMath
/// @notice 512-bit precision mulDiv for overflow-safe calculations
/// @dev Adapted from Uniswap V3 FullMath
library FullMath {
    /// @notice Computes floor(a × b ÷ denominator) with full 512-bit precision
    /// @param a Multiplicand
    /// @param b Multiplier
    /// @param denominator Divisor
    /// @return result Quotient floored to nearest integer
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            uint256 prod0; uint256 prod1;
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            if (prod1 == 0) {
                require(denominator > 0);
                assembly { result := div(prod0, denominator) }
                return result;
            }
            require(denominator > prod1);
            uint256 remainder;
            assembly { remainder := mulmod(a, b, denominator) }
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            assembly { denominator := div(denominator, twos) }
            assembly { prod0 := div(prod0, twos) }
            assembly { twos := add(div(sub(0, twos), twos), 1) }
            prod0 |= prod1 * twos;
            uint256 inv = (3 * denominator) ^ 2;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            result = prod0 * inv;
        }
    }
}

/// @title FixedPointMath
/// @notice Integer square root utility for liquidity scoring
library FixedPointMath {
    /// @notice Computes integer square root of x using Babylonian method
    /// @param x Input value
    /// @return y Floor square root of x
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// ORVIX AGGREGATOR

/// @title OrvixAggregator
/// @author ORVIX Labs
/// @notice Multi-factory V2 AMM aggregator with per-factory fee support, liquidity scoring,
///         price impact filtering, protocol fee split, and deterministic route encoding.
///
/// @dev    Core routing engine iterates whitelisted factories to find optimal execution path.
///         Per-factory fee is propagated through the full call chain: pool selection →
///         reserve-based quote → swap output calculation, ensuring K-invariant consistency
///         across AMMs with differing fee structures (e.g. 0.25%, 0.30%).
///
///         Route encoding uses a compact 64-byte-per-hop binary format:
///         [version(1)] [hopCount(1)] [pool(20) tokenOut(20) feeNum(2) feeDen(2) factory(20)] × N
///
///         Fee model: Protocol takes `protocolFeeRate` bps from input, split 50/50
///         between treasury and integrator before swap execution.
///
///         Native BNB handling:
///         - Input:  Pass `tokenIn == address(0)` and `msg.value == amountIn`.
///                   Contract automatically wraps BNB → WBNB before swap.
///         - Output: Pass `tokenOut == address(0)` to receive native BNB.
///                   Contract automatically unwraps WBNB → BNB after swap.
///         - Path encoding always uses WRAPPED_NATIVE, never address(0).
///           This keeps route validation and encoding clean and consistent.
contract OrvixAggregator is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // STRUCTS

    /// @notice Represents a single hop in a multi-hop swap route
    /// @param pool              Pool contract address (UniswapV2Pair-compatible)
    /// @param tokenOut          Output token of this hop
    /// @param v2FeeNumerator    Fee numerator for this pool's factory (e.g. 9970)
    /// @param v2FeeDenominator  Fee denominator for this pool's factory (e.g. 10000)
    /// @param factory           Factory that deployed this pool
    struct RouteHop {
        address pool;
        address tokenOut;
        uint16 v2FeeNumerator;
        uint16 v2FeeDenominator;
        address factory;
    }

    /// @notice Full quote result including route metadata and execution parameters
    /// @param hops             Decoded hop sequence
    /// @param amountOut        Expected gross output before slippage
    /// @param priceImpact      Estimated price impact in basis points
    /// @param amountOutMin     Minimum acceptable output after slippage deduction
    /// @param path             ABI-encoded route bytes for use in swapExactInput
    /// @param liquidityProfile Human-readable pool depth classification
    /// @param poolLiquidity    Geometric mean liquidity of selected pool
    /// @param bestPool         Address of the highest-scored pool
    struct QuoteResult {
        RouteHop[] hops;
        uint256 amountOut;
        uint256 priceImpact;
        uint256 amountOutMin;
        bytes path;
        string liquidityProfile;
        uint256 poolLiquidity;
        address bestPool;
    }

    /// @dev Internal quote metadata returned by _quoteExactInputInternal
    struct QuoteMeta {
        uint256 amountOut;
        bytes path;
        uint256 priceImpact;
        string liquidityProfile;
        uint256 poolLiquidity;
        address bestPool;
        uint256 bestPoolLiquidity;
    }

    /// @notice Pool assessment result for diagnostics and external tooling
    /// @param pool         Pool address evaluated
    /// @param output       Estimated output for given amountIn
    /// @param liquidity    Geometric mean liquidity (sqrt(r0) × sqrt(r1))
    /// @param priceImpact  Estimated price impact in basis points
    /// @param score        Composite routing score
    /// @param eligible     Whether pool passed all filters
    /// @param failReason   Bitmask of failure reasons (FAIL_* constants)
    struct PoolAssessment {
        address pool;
        uint256 output;
        uint256 liquidity;
        uint256 priceImpact;
        uint256 score;
        bool    eligible;
        uint256 failReason;
    }

    // CONSTANTS

    /// @notice Failure reason: no failure
    uint256 public constant FAIL_NONE           = 0;
    /// @notice Failure reason: one or both reserves are zero
    uint256 public constant FAIL_ZERO_RESERVE   = 1;
    /// @notice Failure reason: swap output computed as zero
    uint256 public constant FAIL_ZERO_OUTPUT    = 2;
    /// @notice Failure reason: pool geometric liquidity is zero
    uint256 public constant FAIL_ZERO_LIQUIDITY = 4;
    /// @notice Failure reason: price impact exceeds configured maximum
    uint256 public constant FAIL_PRICE_IMPACT   = 8;
    /// @notice Failure reason: circuit breaker is active
    uint256 public constant FAIL_CIRCUIT_BREAKER = 16;

    /// @notice Basis points denominator (10,000 = 100%)
    uint256 public constant BPS_DENOMINATOR      = 10_000;
    /// @notice Maximum protocol fee rate in basis points
    uint256 public constant MAX_PROTOCOL_FEE     = 100;
    /// @notice Hard cap on price impact in basis points (30%)
    uint256 public constant ABSOLUTE_MAX_IMPACT  = 3000;
    /// @notice Route encoding version identifier
    uint8   public constant ROUTE_VERSION_V1     = 0x01;
    /// @notice Default swap fee numerator — PancakeSwap V2 (0.25%)
    uint16  public constant DEFAULT_FEE_NUMERATOR   = 9975;
    /// @notice Default swap fee denominator
    uint16  public constant DEFAULT_FEE_DENOMINATOR = 10000;
    /// @notice Maximum hops allowed per route
    uint256 public constant MAX_HOPS             = 255;
    /// @notice Precision multiplier for score computation
    uint256 public constant SCORE_PRECISION      = 1e18;
    /// @notice Maximum number of common (intermediate) tokens
    uint256 public constant MAX_COMMON_TOKENS    = 20;

    // IMMUTABLES

    /// @notice Wrapped native token address (e.g. WBNB on BSC)
    address public immutable WRAPPED_NATIVE;

    // STATE

    /// @notice List of intermediate tokens used for 2-hop route discovery
    address[] public commonTokens;

    /// @notice Ordered list of all whitelisted factory addresses
    address[] public allWhitelistedFactories;

    /// @notice Primary factory used as fallback when no factories specified
    address public primaryFactory;

    /// @notice Protocol fee rate in basis points (default: 25 = 0.25%)
    uint256 public protocolFeeRate = 25;

    /// @notice Maximum allowed price impact in basis points (default: 1000 = 10%)
    uint256 public maxPriceImpact = 1000;

    /// @notice Minimum pool geometric liquidity threshold for eligibility
    uint256 public minPoolLiquidity = 0;

    /// @notice Whether the aggregator has been initialized
    bool public initialized;

    /// @notice Whether the circuit breaker is active (halts all swaps)
    bool public isCircuitBreakerActive;

    /// @notice Factory whitelist status
    mapping(address => bool) public isWhitelistedFactory;

    /// @notice Default treasury address for protocol fee collection
    address public defaultTreasury;

    /// @notice Default integrator address for fee split
    address public defaultIntegrator;

    /// @notice Per-factory swap fee numerator (e.g. 9970 for 0.30% fee)
    /// @dev    Falls back to DEFAULT_FEE_NUMERATOR if unset (zero)
    mapping(address => uint16) public factoryFeeNumerator;

    /// @notice Per-factory swap fee denominator (e.g. 10000)
    /// @dev    Falls back to DEFAULT_FEE_DENOMINATOR if unset (zero)
    mapping(address => uint16) public factoryFeeDenominator;

    /// @dev Cached token decimals to avoid repeated external calls
    mapping(address => uint8)  private _tokenDecimals;
    mapping(address => bool)   private _hasDecimalsCached;

    // EVENTS

    /// @notice Emitted on successful swap execution
    event SwapCompleted(
        address indexed executor,
        address indexed tokenIn,
        address tokenOut,
        uint256 requestedAmountIn,
        uint256 actualAmountIn,
        uint256 amountOut,
        uint256 totalFee
    );

    /// @notice Emitted when protocol fee is distributed to treasury and integrator
    event FeeSplitExecuted(
        address indexed treasury,
        address indexed integrator,
        uint256 treasuryShare,
        uint256 integratorShare
    );

    /// @notice Emitted when protocol fee rate is updated
    event FeeRateAdjusted(uint256 oldRate, uint256 newRate);

    /// @notice Emitted when a factory's whitelist status changes
    event FactoryStatusUpdated(address indexed factory, bool status);

    /// @notice Emitted when circuit breaker state changes
    event CircuitBreakerTriggered(bool isActive);

    /// @notice Emitted when common token list is updated
    event CommonTokensSet(address[] commonTokens);

    /// @notice Emitted when primary factory is updated
    event PrimaryFactoryUpdated(address indexed oldFactory, address indexed newFactory);

    /// @notice Emitted during quote for each pool assessed
    event PoolAssessed(
        address indexed pool,
        uint256 output,
        uint256 liquidity,
        uint256 priceImpact,
        uint256 score,
        bool selected
    );

    /// @notice Emitted when a pool is rejected during quote
    event QuoteRejected(address indexed pool, string reason, uint256 value);

    /// @notice Emitted when per-factory fee is configured
    event FactoryFeeSet(address indexed factory, uint16 feeNumerator, uint16 feeDenominator);

    /// @notice Emitted when a factory is added to the whitelist registry
    event FactoryAddedToRegistry(address indexed factory);

    // ERRORS

    error Expired();
    error SlippageExceeded(uint256 received, uint256 minRequired);
    error NativeTransferFailed();
    error ZeroAddress();
    error NotInitialized();
    error InvalidNativeAmount();
    error AlreadyInitialized();
    error CircuitBreakerActive();
    error NoValidRoute();
    error ZeroAmount();
    error WrapFailed();
    error UnwrapFailed();
    error InvalidRouteVersion(uint8 version);
    error HopContinuityFailed(uint256 hopIndex);
    error OnlyWrappedNative();
    error InvalidBasisPoints();
    error TooManyHops(uint256 hops, uint256 maxHops);
    error InsufficientLiquidity(address pool);
    error InvalidRoute();
    error ExcessivePriceImpact(uint256 impact, uint256 maxAllowed);
    error InvalidRecipient();
    error InvalidFactory();
    error InvalidPool();

    // MODIFIERS

    /// @dev Reverts if aggregator has not been initialized
    modifier onlyInitialized() {
        if (!initialized) revert NotInitialized();
        _;
    }

    /// @dev Reverts if circuit breaker is active
    modifier circuitBreaker() {
        if (isCircuitBreakerActive) revert CircuitBreakerActive();
        _;
    }

    /// @dev Reverts if block.timestamp exceeds deadline
    modifier ensure(uint256 deadline) {
        if (block.timestamp > deadline) revert Expired();
        _;
    }

    // CONSTRUCTOR

    /// @notice Deploys aggregator with immutable wrapped native token
    /// @param wrappedNative Address of the wrapped native token (e.g. WBNB)
    constructor(address wrappedNative) Ownable(msg.sender) {
        if (wrappedNative == address(0)) revert ZeroAddress();
        WRAPPED_NATIVE = wrappedNative;
    }

    // INITIALIZATION

    /// @notice Initializes the aggregator with a default treasury address
    /// @dev    Can only be called once by owner. Sets treasury and activates the contract.
    /// @param treasury Address to receive treasury share of protocol fees
    function initialize(address treasury) external onlyOwner {
        if (initialized) revert AlreadyInitialized();
        if (treasury == address(0)) revert ZeroAddress();
        defaultTreasury = treasury;
        initialized = true;
        isCircuitBreakerActive = false;
    }

    // NATIVE WRAP / UNWRAP

    /// @notice Wraps native token (e.g. BNB → WBNB) held by this contract
    /// @dev    Caller must send native value with the call
    function wrap() external payable nonReentrant {
        if (msg.value == 0) revert ZeroAmount();
        IWrappedNative(WRAPPED_NATIVE).deposit{value: msg.value}();
    }

    /// @notice Unwraps WBNB and returns native BNB to caller
    /// @param amount Amount of wrapped native to unwrap
    function unwrap(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        IWrappedNative(WRAPPED_NATIVE).withdraw(amount);
        (bool sent,) = msg.sender.call{value: amount}("");
        if (!sent) revert NativeTransferFailed();
    }

    // ROUTE ENCODING / DECODING

    /// @notice Encodes a RouteHop array into compact binary path bytes
    /// @dev    Format: [0x01][hopCount][pool(20)][tokenOut(20)][feeNum(2)][feeDen(2)][factory(20)] × N
    ///         Each hop occupies exactly 64 bytes after the 2-byte header.
    ///         tokenOut in each hop always encodes the ERC20 address (WRAPPED_NATIVE for native output).
    /// @param hops Array of RouteHop structs to encode
    /// @return packed ABI-packed binary route
    function _encodePath(RouteHop[] memory hops) private pure returns (bytes memory packed) {
        uint256 len = hops.length;
        if (len > MAX_HOPS) revert TooManyHops(len, MAX_HOPS);
        packed = abi.encodePacked(ROUTE_VERSION_V1, uint8(len));
        for (uint256 i = 0; i < len; i++) {
            packed = abi.encodePacked(
                packed,
                hops[i].pool,
                hops[i].tokenOut,
                hops[i].v2FeeNumerator,
                hops[i].v2FeeDenominator,
                hops[i].factory
            );
        }
    }

    /// @notice Decodes binary path bytes into a RouteHop array
    /// @dev    Validates version byte and minimum length before decoding.
    ///         Uses inline assembly for gas-efficient pointer arithmetic.
    /// @param data Encoded route bytes produced by _encodePath
    /// @return hops Decoded RouteHop array
    function _decodePath(bytes memory data) private pure returns (RouteHop[] memory hops) {
        if (data.length < 2) revert InvalidRoute();
        uint8 version;
        uint8 hopsLength;
        assembly {
            version    := byte(0, mload(add(data, 32)))
            hopsLength := byte(0, mload(add(data, 33)))
        }
        if (version != ROUTE_VERSION_V1) revert InvalidRouteVersion(version);
        uint256 expectedLen = 2 + uint256(hopsLength) * 64;
        if (data.length < expectedLen) revert InvalidRoute();
        hops = new RouteHop[](hopsLength);
        uint256 ptr;
        assembly { ptr := add(data, 34) }
        for (uint256 i = 0; i < hopsLength; i++) {
            address pool;
            address tokenOut;
            uint16 feeNum;
            uint16 feeDen;
            address factory;
            assembly {
                pool     := shr(96, mload(ptr))
                ptr      := add(ptr, 20)
                tokenOut := shr(96, mload(ptr))
                ptr      := add(ptr, 20)
                feeNum   := shr(240, mload(ptr))
                ptr      := add(ptr, 2)
                feeDen   := shr(240, mload(ptr))
                ptr      := add(ptr, 2)
                factory  := shr(96, mload(ptr))
                ptr      := add(ptr, 20)
            }
            hops[i] = RouteHop({
                pool: pool,
                tokenOut: tokenOut,
                v2FeeNumerator: feeNum,
                v2FeeDenominator: feeDen,
                factory: factory
            });
        }
    }

    // SWAP EXECUTION

    /// @notice Executes a multi-hop swap across pre-validated V2 pools
    /// @dev    - Transfers tokenIn to each pool in sequence
    ///         - Measures actual amount received via balance delta (tax token support)
    ///         - Re-computes amountOut if fee-on-transfer reduces actual input
    ///         - Per-hop fee is read from encoded path (set by _buildHop)
    /// @param hops     Decoded route hop sequence
    /// @param tokenIn  Input token for first hop
    /// @param amountIn Input amount (after protocol fee deduction)
    /// @return finalAmount Actual output received from last hop
    function _executeDirectSwap(
        RouteHop[] memory hops,
        address tokenIn,
        uint256 amountIn
    ) private returns (uint256 finalAmount) {
        address currentToken = tokenIn;
        uint256 currentAmount = amountIn;

        for (uint256 i = 0; i < hops.length; i++) {
            RouteHop memory hop = hops[i];
            (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(hop.pool).getReserves();
            address token0 = IUniswapV2Pair(hop.pool).token0();
            bool isToken0Input = (currentToken == token0);

            uint256 expectedOut = isToken0Input
                ? _calculateSwapOutput(currentAmount, reserve0, reserve1, hop)
                : _calculateSwapOutput(currentAmount, reserve1, reserve0, hop);

            if (expectedOut == 0) revert InsufficientLiquidity(hop.pool);

            address hopRecipient = address(this);
            uint256 poolBalanceBefore = IERC20(currentToken).balanceOf(hop.pool);
            IERC20(currentToken).safeTransfer(hop.pool, currentAmount);
            uint256 poolBalanceAfter = IERC20(currentToken).balanceOf(hop.pool);
            uint256 actualAmountSent = poolBalanceAfter - poolBalanceBefore;

            uint256 amountOut;
            if (actualAmountSent < currentAmount) {
                amountOut = isToken0Input
                    ? _calculateSwapOutput(actualAmountSent, reserve0, reserve1, hop)
                    : _calculateSwapOutput(actualAmountSent, reserve1, reserve0, hop);
            } else {
                amountOut = expectedOut;
            }

            if (amountOut == 0) revert InsufficientLiquidity(hop.pool);

            uint256 recipientBalanceBefore = IERC20(hop.tokenOut).balanceOf(hopRecipient);
            if (isToken0Input) {
                IUniswapV2Pair(hop.pool).swap(0, amountOut, hopRecipient, "");
            } else {
                IUniswapV2Pair(hop.pool).swap(amountOut, 0, hopRecipient, "");
            }
            uint256 recipientBalanceAfter = IERC20(hop.tokenOut).balanceOf(hopRecipient);
            uint256 actualReceived = recipientBalanceAfter - recipientBalanceBefore;

            if (actualReceived == 0) revert InsufficientLiquidity(hop.pool);

            currentToken = hop.tokenOut;
            currentAmount = actualReceived;
        }

        finalAmount = currentAmount;
    }

    /// @notice Computes expected swap output using constant product formula with per-hop fee
    /// @dev    Formula: amountOut = (amountIn × feeNumerator × reserveOut)
    ///                            ÷ (reserveIn × feeDenominator + amountIn × feeNumerator)
    /// @param amountIn   Input amount
    /// @param reserveIn  Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @param hop        RouteHop containing factory-specific fee parameters
    /// @return amountOut Computed output amount
    function _calculateSwapOutput(
        uint256 amountIn,
        uint112 reserveIn,
        uint112 reserveOut,
        RouteHop memory hop
    ) private pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * hop.v2FeeNumerator;
        uint256 numerator = amountInWithFee * uint256(reserveOut);
        uint256 denominator = (uint256(reserveIn) * hop.v2FeeDenominator) + amountInWithFee;
        amountOut = denominator == 0 ? 0 : numerator / denominator;
    }

    // FACTORY RESOLUTION

    /// @dev Resolves calldata factory list to memory, falling back to whitelisted set
    function _resolveFactoriesToMemory(address[] calldata factories) private view returns (address[] memory) {
        if (factories.length == 0) return allWhitelistedFactories;
        address[] memory out = new address[](factories.length);
        for (uint256 i = 0; i < factories.length; i++) out[i] = factories[i];
        return out;
    }

    /// @dev Resolves memory factory list, falling back to whitelist then primaryFactory
    function _resolveFactories(address[] memory factories) internal view returns (address[] memory) {
        if (factories.length == 0) {
            if (allWhitelistedFactories.length > 0) return allWhitelistedFactories;
            if (primaryFactory != address(0)) {
                address[] memory out = new address[](1);
                out[0] = primaryFactory;
                return out;
            }
            return new address[](0);
        }
        return factories;
    }

    // LIQUIDITY PROFILING

    /// @dev Returns a human-readable liquidity depth classification
    /// @param liquidity Geometric mean liquidity value
    /// @return Liquidity profile string
    function _getLiquidityProfileString(uint256 liquidity) internal view returns (string memory) {
        if (liquidity < minPoolLiquidity)  return "LOW_LIQUIDITY";
        if (liquidity < 100 ether)         return "MEDIUM_LIQUIDITY";
        if (liquidity < 1000 ether)        return "HIGH_LIQUIDITY";
        return "DEEP_LIQUIDITY";
    }

    // QUOTE ENGINE

    /// @notice Core quote engine — evaluates direct and 2-hop routes across all factories
    /// @dev    - Scores pools using: output, sqrt-reserve liquidity, price impact penalty
    ///         - Per-factory fee is propagated to _quoteSwapFromReserves and _buildHop
    ///         - Rejects pools above maxImpact
    ///         - Common tokens used as intermediates for 2-hop discovery
    ///         - tokenIn/tokenOut normalized: address(0) → WRAPPED_NATIVE internally.
    ///           Path always encodes WRAPPED_NATIVE (never address(0)).
    /// @param tokenIn   Input token address (address(0) = native)
    /// @param tokenOut  Output token address (address(0) = native)
    /// @param amountIn  Gross input amount
    /// @param factories Factory list to search (empty = all whitelisted)
    /// @param maxImpact Maximum price impact in basis points
    /// @return meta     QuoteMeta containing best route and associated metrics
    function _quoteExactInputInternal(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] memory factories,
        uint256 maxImpact
    ) private view returns (QuoteMeta memory meta) {
        address tIn  = tokenIn  == address(0) ? WRAPPED_NATIVE : tokenIn;
        address tOut = tokenOut == address(0) ? WRAPPED_NATIVE : tokenOut;

        if (tIn == tOut) {
            meta.amountOut        = amountIn;
            meta.path             = "";
            meta.priceImpact      = 0;
            meta.liquidityProfile = "DEEP_LIQUIDITY";
            meta.poolLiquidity    = type(uint256).max;
            meta.bestPool         = address(0);
            meta.bestPoolLiquidity = type(uint256).max;
            return meta;
        }

        address[] memory resolvedFactories = _resolveFactories(factories);
        if (resolvedFactories.length == 0) revert NoValidRoute();

        uint256       bestAmountOut = 0;
        address       bestPool      = address(0);
        uint256       bestImpact    = 0;
        uint256       bestLiquidity = 0;
        RouteHop[] memory bestHops;
        uint256       bestScore     = 0;

        (
            RouteHop[] memory directHops,
            uint256 directOutput,
            uint256 directImpact,
            uint256 directScore,
            uint256 directLiquidity
        ) = _tryDirectSwapScoredWithLiquidity(tIn, tOut, amountIn, resolvedFactories, maxImpact);

        if (directOutput > 0) {
            bestHops      = directHops;
            bestAmountOut = directOutput;
            bestImpact    = directImpact;
            bestLiquidity = directLiquidity;
            bestPool      = directHops.length > 0 ? directHops[0].pool : address(0);
            bestScore     = directScore;
        }

        for (uint256 i = 0; i < commonTokens.length; i++) {
            address mid = commonTokens[i];
            if (mid == tIn || mid == tOut) continue;

            (
                RouteHop[] memory route,
                uint256 output,
                uint256 impact,
                uint256 score,
                uint256 liquidity
            ) = _tryMultiHopSwapScoredWithLiquidity(tIn, mid, tOut, amountIn, resolvedFactories, maxImpact);

            if (output > 0 && score > bestScore) {
                bestHops      = route;
                bestAmountOut = output;
                bestImpact    = impact;
                bestLiquidity = liquidity;
                bestPool      = route.length > 0 ? route[0].pool : address(0);
                bestScore     = score;
            }
        }

        if (bestAmountOut == 0) revert NoValidRoute();

        meta.amountOut        = bestAmountOut;
        meta.path             = _encodePath(bestHops);
        meta.priceImpact      = bestImpact;
        meta.liquidityProfile = _getLiquidityProfileString(bestLiquidity);
        meta.poolLiquidity    = bestLiquidity;
        meta.bestPool         = bestPool;
        meta.bestPoolLiquidity = bestLiquidity;
    }

    /// @dev Evaluates all factories for a direct single-hop route and returns best scored result
    function _tryDirectSwapScoredWithLiquidity(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] memory factories,
        uint256 maxImpact
    ) private view returns (
        RouteHop[] memory hops,
        uint256 output,
        uint256 impact,
        uint256 score,
        uint256 liquidity
    ) {
        (address pool, address factory) = _selectOptimalPoolScored(tokenIn, tokenOut, factories, amountIn, maxImpact);
        if (pool == address(0)) return (new RouteHop[](0), 0, 0, 0, 0);

        hops    = new RouteHop[](1);
        hops[0] = _buildHop(pool, tokenOut, factory);

        output = _quoteV2Swap(hops[0], tokenIn, amountIn);
        if (output == 0) return (new RouteHop[](0), 0, 0, 0, 0);

        impact = _calculatePriceImpact(hops[0], tokenIn, amountIn, output);
        if (impact > maxImpact) return (new RouteHop[](0), 0, 0, 0, 0);

        (bool hasLiquidity, uint256 liq) = _getPoolLiquidity(pool);
        if (!hasLiquidity) return (new RouteHop[](0), 0, 0, 0, 0);
        liquidity = liq;

        score = _computePathScore(output, liquidity, impact);
    }

    /// @dev Evaluates a 2-hop route through an intermediate token and returns best scored result
    function _tryMultiHopSwapScoredWithLiquidity(
        address tokenIn,
        address intermediate,
        address tokenOut,
        uint256 amountIn,
        address[] memory factories,
        uint256 maxImpact
    ) private view returns (
        RouteHop[] memory hops,
        uint256 output,
        uint256 impact,
        uint256 score,
        uint256 liquidity
    ) {
        (address pool1, address factory1) = _selectOptimalPoolScored(tokenIn, intermediate, factories, amountIn, maxImpact);
        if (pool1 == address(0)) return (new RouteHop[](0), 0, 0, 0, 0);

        hops    = new RouteHop[](2);
        hops[0] = _buildHop(pool1, intermediate, factory1);

        uint256 out1 = _quoteV2Swap(hops[0], tokenIn, amountIn);
        if (out1 == 0) return (new RouteHop[](0), 0, 0, 0, 0);

        uint256 impact1 = _calculatePriceImpact(hops[0], tokenIn, amountIn, out1);
        if (impact1 > maxImpact) return (new RouteHop[](0), 0, 0, 0, 0);

        (address pool2, address factory2) = _selectOptimalPoolScored(intermediate, tokenOut, factories, out1, maxImpact);
        if (pool2 == address(0)) return (new RouteHop[](0), 0, 0, 0, 0);

        hops[1] = _buildHop(pool2, tokenOut, factory2);

        output = _quoteV2Swap(hops[1], intermediate, out1);
        if (output == 0) return (new RouteHop[](0), 0, 0, 0, 0);

        uint256 impact2 = _calculatePriceImpact(hops[1], intermediate, out1, output);
        if (impact2 > maxImpact) return (new RouteHop[](0), 0, 0, 0, 0);

        impact = impact1 + impact2;

        (bool ok1, uint256 liq1) = _getPoolLiquidity(pool1);
        (bool ok2, uint256 liq2) = _getPoolLiquidity(pool2);
        if (!ok1 || !ok2) return (new RouteHop[](0), 0, 0, 0, 0);

        liquidity = FixedPointMath.sqrt(liq1 * liq2);
        uint256 pathOutputStability = FixedPointMath.sqrt(out1 * output);
        score = _computePathScore(pathOutputStability, liquidity, impact);
    }

    /// @notice Selects the highest-scored pool for a token pair across all factories
    /// @dev    Per-factory fee is passed to _assessPool → _quoteSwapFromReserves,
    ///         ensuring consistent K-invariant calculation for each AMM.
    /// @param token0    Input token
    /// @param token1    Output token
    /// @param factories Factories to evaluate
    /// @param amountIn  Input amount for scoring
    /// @param maxImpact Maximum acceptable price impact
    /// @return bestPool    Address of highest-scored pool
    /// @return bestFactory Factory that deployed bestPool
    function _selectOptimalPoolScored(
        address token0,
        address token1,
        address[] memory factories,
        uint256 amountIn,
        uint256 maxImpact
    ) private view returns (address bestPool, address bestFactory) {
        uint256 bestScore     = 0;
        address bestPoolTemp  = address(0);
        address bestFactoryTemp = address(0);

        for (uint256 i = 0; i < factories.length; i++) {
            address factory = factories[i];
            if (factory.code.length == 0) continue;
            if (!isWhitelistedFactory[factory]) continue;

            address pair = _getPairFromFactory(factory, token0, token1);
            if (pair == address(0)) continue;

            (uint256 output, uint256 liquidity, uint256 impact,) =
                _assessPool(token0, token1, amountIn, pair, factory, maxImpact);

            if (output > 0 && impact <= maxImpact) {
                uint256 poolScore = _computePathScore(output, liquidity, impact);
                if (poolScore > bestScore) {
                    bestScore       = poolScore;
                    bestPoolTemp    = pair;
                    bestFactoryTemp = factory;
                }
            }
        }

        bestPool    = bestPoolTemp;
        bestFactory = bestFactoryTemp;
    }

    /// @notice Evaluates a single pool for output, liquidity, impact, and routing score
    /// @dev    Per-factory fee is forwarded to _quoteSwapFromReserves to ensure
    ///         pool selection scoring uses the same fee as swap execution.
    ///         This prevents K-invariant violations when AMMs differ in fee structure.
    /// @param token0    Input token
    /// @param token1    Output token
    /// @param amountIn  Input amount
    /// @param pair      Pool address to evaluate
    /// @param factory   Factory that deployed this pool (used for fee lookup)
    /// @param maxImpact Maximum acceptable price impact in basis points
    /// @return output   Estimated output amount
    /// @return liquidity Geometric mean liquidity
    /// @return impact   Estimated price impact in basis points
    /// @return score    Composite routing score
    function _assessPool(
        address token0,
        address token1,
        uint256 amountIn,
        address pair,
        address factory,
        uint256 maxImpact
    ) private view returns (uint256 output, uint256 liquidity, uint256 impact, uint256 score) {
        (uint112 r0, uint112 r1, address t0, address t1) = _getPairReservesAndTokens(pair);

        if (r0 == 0 || r1 == 0) {
            return (0, 0, 0, 0);
        }

        uint8 dec0 = _getDecimalsStatic(t0);
        uint8 dec1 = _getDecimalsStatic(t1);

        uint256 r0Norm = _normalizeReserve(r0, dec0);
        uint256 r1Norm = _normalizeReserve(r1, dec1);

        liquidity = FixedPointMath.sqrt(r0Norm) * FixedPointMath.sqrt(r1Norm);

        if (liquidity == 0) {
            return (0, 0, 0, 0);
        }

        output = _quoteSwapFromReserves(r0, r1, t0, token0, token1, amountIn, factory);

        if (output == 0) {
            return (0, 0, 0, 0);
        }

        impact = _calculatePriceImpactFromReserves(r0, r1, t0, t1, dec0, dec1, token0, amountIn, output);

        if (impact > maxImpact) {
            return (0, 0, 0, 0);
        }

        score = _computePathScore(output, liquidity, impact);
    }

    // EXTERNAL SWAP ENTRY POINT

    /// @notice Executes a swap along a pre-quoted route
    /// @dev    - Decodes binary path into RouteHop sequence
    ///         - Validates route integrity against factory registry
    ///         - Deducts protocol fee from input before execution
    ///         - Native BNB input: pass `tokenIn == address(0)` with `msg.value == amountIn`
    ///         - Native BNB output: pass `tokenOut == address(0)` to receive BNB
    ///         - Path always encodes WRAPPED_NATIVE as the final hop tokenOut
    ///         - Supports both single-hop and multi-hop routes
    ///
    /// @param tokenIn      Input token (address(0) = native BNB)
    /// @param tokenOut     Output token (address(0) = native BNB)
    /// @param amountIn     Gross input amount
    /// @param amountOutMin Minimum acceptable output (reverts on SlippageExceeded)
    /// @param recipient    Address to receive output tokens or native BNB
    /// @param deadline     Unix timestamp after which transaction reverts
    /// @param path         Encoded route bytes from quoteExactInput
    /// @param treasury     Override treasury address (address(0) = use default)
    /// @param integrator   Override integrator address (address(0) = use default)
    /// @return amountOut   Actual output amount received by recipient
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient,
        uint256 deadline,
        bytes calldata path,
        address treasury,
        address integrator
    )
        external
        payable
        nonReentrant
        onlyInitialized
        circuitBreaker
        ensure(deadline)
        returns (uint256 amountOut)
    {
        if (recipient == address(0)) revert InvalidRecipient();
        if (amountIn == 0) revert ZeroAmount();
        if (path.length == 0) revert InvalidRoute();

        bool inputNative  = tokenIn  == address(0);
        bool outputNative = tokenOut == address(0);

        address normalizedTokenIn  = inputNative  ? WRAPPED_NATIVE : tokenIn;
        address normalizedTokenOut = outputNative ? WRAPPED_NATIVE : tokenOut;

        uint256 actualAmountIn;

        if (inputNative) {
            // Native BNB input: must have exact msg.value
            if (msg.value != amountIn) revert InvalidNativeAmount();
            IWrappedNative(WRAPPED_NATIVE).deposit{value: msg.value}();
            actualAmountIn = msg.value;
        } else {
            // ERC20 input: msg.value must be 0
            if (msg.value != 0) revert InvalidNativeAmount();
            uint256 balanceBefore = IERC20(normalizedTokenIn).balanceOf(address(this));
            IERC20(normalizedTokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
            uint256 balanceAfter = IERC20(normalizedTokenIn).balanceOf(address(this));
            actualAmountIn = balanceAfter - balanceBefore;
        }

        if (actualAmountIn == 0) revert ZeroAmount();

        uint256 scaledAmountOutMin = amountIn > 0
            ? (amountOutMin * actualAmountIn) / amountIn
            : amountOutMin;

        uint256 fee = 0;
        uint256 amountAfterFee = actualAmountIn;
        if (protocolFeeRate > 0) {
            fee = (actualAmountIn * protocolFeeRate) / BPS_DENOMINATOR;
            amountAfterFee = actualAmountIn - fee;
        }

        RouteHop[] memory hops = _decodePath(path);
        _validateRouteIntegrity(hops, normalizedTokenIn, normalizedTokenOut);

        uint256 swapOutput = _executeDirectSwap(hops, normalizedTokenIn, amountAfterFee);

        uint256 balBefore;
        uint256 balAfter;

        if (outputNative) {
            // Unwrap WBNB → native BNB and deliver to recipient
            balBefore = recipient.balance;
            IWrappedNative(WRAPPED_NATIVE).withdraw(swapOutput);
            (bool sent,) = recipient.call{value: swapOutput}("");
            if (!sent) revert NativeTransferFailed();
            balAfter = recipient.balance;
            amountOut = balAfter - balBefore;
        } else {
            // Deliver ERC20 (including WBNB) directly to recipient
            balBefore = IERC20(normalizedTokenOut).balanceOf(recipient);
            IERC20(normalizedTokenOut).safeTransfer(recipient, swapOutput);
            balAfter = IERC20(normalizedTokenOut).balanceOf(recipient);
            amountOut = balAfter - balBefore;
        }

        if (amountOut < scaledAmountOutMin) revert SlippageExceeded(amountOut, scaledAmountOutMin);

        if (fee > 0 && defaultTreasury != address(0)) {
            _splitFee(normalizedTokenIn, fee, treasury, integrator);
        }

        emit SwapCompleted(msg.sender, tokenIn, tokenOut, amountIn, actualAmountIn, amountOut, fee);
    }

    // FEE SPLIT

    /// @notice Distributes protocol fee between treasury and integrator (50/50)
    /// @dev    If no integrator is set, full fee goes to treasury.
    ///         Supports both ERC20 and wrapped native fee tokens.
    /// @param token        Input token address
    /// @param totalFee     Total fee amount to distribute
    /// @param treasury     Override treasury (address(0) = use default)
    /// @param integrator   Override integrator (address(0) = use default)
    function _splitFee(
        address token,
        uint256 totalFee,
        address treasury,
        address integrator
    ) internal {
        address _treasury   = treasury   != address(0) ? treasury   : defaultTreasury;
        address _integrator = integrator != address(0) ? integrator : defaultIntegrator;

        uint256 integratorShare = (_integrator != address(0)) ? totalFee / 2 : 0;
        uint256 treasuryShare   = totalFee - integratorShare;

        if (treasuryShare > 0 && _treasury != address(0)) {
            if (token == address(0) || token == WRAPPED_NATIVE) {
                IWrappedNative(WRAPPED_NATIVE).transfer(_treasury, treasuryShare);
            } else {
                IERC20(token).safeTransfer(_treasury, treasuryShare);
            }
        }

        if (integratorShare > 0 && _integrator != address(0)) {
            if (token == address(0) || token == WRAPPED_NATIVE) {
                IWrappedNative(WRAPPED_NATIVE).transfer(_integrator, integratorShare);
            } else {
                IERC20(token).safeTransfer(_integrator, integratorShare);
            }
        }

        emit FeeSplitExecuted(_treasury, _integrator, treasuryShare, integratorShare);
    }

    // ROUTE VALIDATION

    /// @notice Validates route hop continuity and factory-pool consistency
    /// @dev    - Verifies first hop input token matches swap tokenIn
    ///         - Checks each hop's tokenOut connects to next hop's tokenIn
    ///         - Confirms each pool exists via factory.getPair()
    ///         - Rejects unwhitelisted factories to prevent route injection
    ///         - expectedTokenOut must be the ERC20 address (WRAPPED_NATIVE, never address(0));
    ///           native unwrap is handled after validation via outputNative flag.
    /// @param hops             Decoded route hop sequence
    /// @param expectedTokenIn  Normalized input token for first hop (never address(0))
    /// @param expectedTokenOut Expected final output ERC20 token (never address(0))
    function _validateRouteIntegrity(
        RouteHop[] memory hops,
        address expectedTokenIn,
        address expectedTokenOut
    ) private view {
        if (hops.length == 0) revert InvalidRoute();

        address expectedIn   = expectedTokenIn;
        address firstTokenIn = _resolvePoolTokenIn(hops[0].pool, hops[0].tokenOut);
        if (firstTokenIn != expectedIn) revert HopContinuityFailed(0);

        for (uint256 i = 0; i < hops.length - 1; i++) {
            if (hops[i].tokenOut != _resolvePoolTokenIn(hops[i + 1].pool, hops[i + 1].tokenOut)) {
                revert HopContinuityFailed(i);
            }
        }

        address lastOut = hops[hops.length - 1].tokenOut;
        if (lastOut != expectedTokenOut) revert HopContinuityFailed(hops.length - 1);

        for (uint256 i = 0; i < hops.length; i++) {
            if (hops[i].pool.code.length == 0)  revert InvalidRoute();
            if (hops[i].tokenOut == address(0)) revert InvalidRoute();
            if (!isWhitelistedFactory[hops[i].factory]) revert InvalidFactory();

            address expectedPool = IUniswapV2Factory(hops[i].factory).getPair(
                (i == 0) ? expectedTokenIn : hops[i - 1].tokenOut,
                hops[i].tokenOut
            );
            if (expectedPool != hops[i].pool) revert InvalidPool();
        }
    }

    /// @dev Resolves the input token of a pool given its output token
    function _resolvePoolTokenIn(address pool, address tokenOut) private view returns (address tokenIn) {
        address t0 = IUniswapV2Pair(pool).token0();
        address t1 = IUniswapV2Pair(pool).token1();
        if (t0 == t1) revert InvalidPool();
        tokenIn = t0 == tokenOut ? t1 : t0;
    }

    // PUBLIC QUOTE FUNCTIONS

    /// @notice Returns full route metadata including hops, liquidity profile, and amountOutMin
    /// @dev    Unified quoting engine that returns complete QuoteResult in a single view call.
    ///         Path always encodes WRAPPED_NATIVE for native output pairs.
    ///         Pass the returned path to swapExactInput with tokenOut == address(0) for native BNB delivery.
    ///
    /// @param tokenIn     Input token address (address(0) = native)
    /// @param tokenOut    Output token address (address(0) = native)
    /// @param amountIn    Input amount
    /// @param factories   Factories to search (empty = all whitelisted)
    /// @param slippageBps Slippage tolerance in basis points
    /// @return result     Full QuoteResult struct
    function quoteExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] calldata factories,
        uint256 slippageBps
    ) external view returns (QuoteResult memory result) {
        if (slippageBps > BPS_DENOMINATOR) revert InvalidBasisPoints();
        if (amountIn == 0)                 revert ZeroAmount();

        address[] memory resolvedFactories = _resolveFactoriesToMemory(factories);

        // Normalize address(0) → WRAPPED_NATIVE
        address tIn  = tokenIn  == address(0) ? WRAPPED_NATIVE : tokenIn;
        address tOut = tokenOut == address(0) ? WRAPPED_NATIVE : tokenOut;

        QuoteMeta memory meta = _quoteExactInputInternal(tIn, tOut, amountIn, resolvedFactories, maxPriceImpact);

        RouteHop[] memory hops;
        if (meta.path.length > 0) hops = _decodePath(meta.path);

        result = QuoteResult({
            hops:             hops,
            amountOut:        meta.amountOut,
            priceImpact:      meta.priceImpact,
            amountOutMin:     FullMath.mulDiv(meta.amountOut, (BPS_DENOMINATOR - slippageBps), BPS_DENOMINATOR),
            path:             meta.path,
            liquidityProfile: meta.liquidityProfile,
            poolLiquidity:    meta.poolLiquidity,
            bestPool:         meta.bestPool
        });
    }

    // POOL ASSESSMENT (Diagnostics)

    /// @notice Evaluates all available pools for a token pair across factories
    /// @dev    Used for diagnostics, routing analysis, and SDK tooling.
    ///         Per-factory fee is forwarded to _assessPoolFull → _quoteSwapFromReserves.
    /// @param tokenIn   Input token
    /// @param tokenOut  Output token
    /// @param amountIn  Input amount for quote simulation
    /// @param factories Factories to evaluate (empty = all whitelisted)
    /// @param rawMode   If true, skips price impact filter for raw data output
    /// @return assessments Array of PoolAssessment structs for each discovered pool
    function assessPools(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] calldata factories,
        bool rawMode
    ) external view returns (PoolAssessment[] memory assessments) {
        address tIn  = tokenIn  == address(0) ? WRAPPED_NATIVE : tokenIn;
        address tOut = tokenOut == address(0) ? WRAPPED_NATIVE : tokenOut;
        address[] memory resolvedFactories = _resolveFactoriesToMemory(factories);

        uint256 poolCount = 0;
        for (uint256 i = 0; i < resolvedFactories.length; ) {
            address factory = resolvedFactories[i];
            if (factory.code.length != 0 &&
                isWhitelistedFactory[factory] &&
                _getPairFromFactory(factory, tIn, tOut) != address(0)) {
                poolCount++;
            }
            unchecked { ++i; }
        }

        assessments = new PoolAssessment[](poolCount);
        uint256 index = 0;

        for (uint256 i = 0; i < resolvedFactories.length; ) {
            address factory = resolvedFactories[i];
            if (factory.code.length == 0 || !isWhitelistedFactory[factory]) {
                unchecked { ++i; }
                continue;
            }

            address pair = _getPairFromFactory(factory, tIn, tOut);
            if (pair == address(0)) {
                unchecked { ++i; }
                continue;
            }

            assessments[index] = _assessPoolFull(tIn, tOut, amountIn, pair, factory, rawMode);
            unchecked { ++i; ++index; }
        }
    }

    /// @dev Full pool assessment including all failure reason flags
    /// @param token0   Input token
    /// @param token1   Output token
    /// @param amountIn Input amount
    /// @param pair     Pool address
    /// @param factory  Factory that deployed the pool (used for fee lookup)
    /// @param rawMode  Skip price impact filter if true
    function _assessPoolFull(
        address token0,
        address token1,
        uint256 amountIn,
        address pair,
        address factory,
        bool rawMode
    ) private view returns (PoolAssessment memory result) {
        result.pool = pair;

        if (isCircuitBreakerActive) {
            result.failReason = FAIL_CIRCUIT_BREAKER;
            result.eligible   = false;
            return result;
        }

        (uint112 r0, uint112 r1, address t0, address t1) = _getPairReservesAndTokens(pair);

        if (r0 == 0 || r1 == 0) {
            result.failReason = FAIL_ZERO_RESERVE;
            result.eligible   = false;
            return result;
        }

        uint8 dec0 = _getDecimalsStatic(t0);
        uint8 dec1 = _getDecimalsStatic(t1);

        uint256 r0Norm = _normalizeReserve(r0, dec0);
        uint256 r1Norm = _normalizeReserve(r1, dec1);

        result.liquidity = FixedPointMath.sqrt(r0Norm) * FixedPointMath.sqrt(r1Norm);

        if (result.liquidity == 0) {
            result.failReason = FAIL_ZERO_LIQUIDITY;
            result.eligible   = false;
            return result;
        }

        result.output = _quoteSwapFromReserves(r0, r1, t0, token0, token1, amountIn, factory);

        if (result.output == 0) {
            result.failReason = FAIL_ZERO_OUTPUT;
            result.eligible   = false;
            return result;
        }

        result.priceImpact = _calculatePriceImpactFromReserves(
            r0, r1, t0, t1, dec0, dec1, token0, amountIn, result.output
        );

        result.score = _computePathScore(result.output, result.liquidity, result.priceImpact);

        uint256 failReason = FAIL_NONE;
        if (!rawMode && result.priceImpact > maxPriceImpact) {
            failReason |= FAIL_PRICE_IMPACT;
        }

        result.failReason = failReason;
        result.eligible   = (failReason == FAIL_NONE);
    }

    // INTERNAL PRICING HELPERS

    /// @dev Reads reserves and token addresses from a UniswapV2Pair
    function _getPairReservesAndTokens(address pair)
        private view
        returns (uint112 r0, uint112 r1, address t0, address t1)
    {
        t0 = IUniswapV2Pair(pair).token0();
        t1 = IUniswapV2Pair(pair).token1();
        (r0, r1,) = IUniswapV2Pair(pair).getReserves();
    }

    /// @notice Reserve-based swap quote using per-factory fee
    /// @dev    Called from _assessPool and _assessPoolFull to ensure pool selection
    ///         scoring uses the same fee parameters as actual swap execution,
    ///         preventing K-invariant violations on AMMs with non-standard fees.
    /// @param r0       Raw reserve of token0
    /// @param r1       Raw reserve of token1
    /// @param t0       Address of token0
    /// @param tokenIn  Input token address
    /// @param tokenOut Output token address (unused — direction resolved via t0)
    /// @param amountIn Input amount
    /// @param factory  Factory address for fee lookup
    /// @return output  Estimated output amount
    function _quoteSwapFromReserves(
        uint112 r0,
        uint112 r1,
        address t0,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address factory
    ) private view returns (uint256 output) {
        (uint256 resIn, uint256 resOut) = tokenIn == t0
            ? (uint256(r0), uint256(r1))
            : (uint256(r1), uint256(r0));

        uint16 feeNum = factoryFeeNumerator[factory];
        uint16 feeDen = factoryFeeDenominator[factory];
        if (feeNum == 0) feeNum = DEFAULT_FEE_NUMERATOR;
        if (feeDen == 0) feeDen = DEFAULT_FEE_DENOMINATOR;

        uint256 amountInWithFee = amountIn * feeNum;
        uint256 denominator     = (resIn * feeDen) + amountInWithFee;
        output = denominator == 0 ? 0 : (amountInWithFee * resOut) / denominator;
    }

    /// @dev Quote swap output using fee encoded in RouteHop (used for multi-hop chaining)
    function _quoteV2Swap(
        RouteHop memory hop,
        address tokenIn,
        uint256 amountIn
    ) private view returns (uint256 output) {
        (uint112 r0, uint112 r1,) = IUniswapV2Pair(hop.pool).getReserves();
        address t0 = IUniswapV2Pair(hop.pool).token0();

        (uint256 resIn, uint256 resOut) = tokenIn == t0
            ? (uint256(r0), uint256(r1))
            : (uint256(r1), uint256(r0));

        uint256 amountInWithFee = amountIn * hop.v2FeeNumerator;
        uint256 denominator     = (resIn * hop.v2FeeDenominator) + amountInWithFee;
        output = denominator == 0 ? 0 : (amountInWithFee * resOut) / denominator;
    }

    /// @dev Calculates price impact from raw reserves and decimal normalization
    function _calculatePriceImpactFromReserves(
        uint112 r0, uint112 r1,
        address t0, address,
        uint8 dec0, uint8 dec1,
        address tokenIn,
        uint256 amountIn,
        uint256 expectedOut
    ) private pure returns (uint256 priceImpact) {
        uint8 decIn  = tokenIn == t0 ? dec0 : dec1;
        uint8 decOut = tokenIn == t0 ? dec1 : dec0;

        uint256 rInNorm  = tokenIn == t0
            ? _normalizeReserve(r0, dec0) : _normalizeReserve(r1, dec1);
        uint256 rOutNorm = tokenIn == t0
            ? _normalizeReserve(r1, dec1) : _normalizeReserve(r0, dec0);

        if (rInNorm == 0 || rOutNorm == 0) return 0;

        uint256 amountInNorm  = _normalizeAmount(amountIn,    decIn);
        uint256 amountOutNorm = _normalizeAmount(expectedOut, decOut);

        if (amountInNorm == 0 || amountOutNorm == 0) return 0;

        uint256 executionRatio = FullMath.mulDiv(
            amountOutNorm * rInNorm,
            1e18,
            amountInNorm * rOutNorm
        );

        if (executionRatio >= 1e18) return 0;
        priceImpact = FullMath.mulDiv(1e18 - executionRatio, BPS_DENOMINATOR, 1e18);
    }

    /// @dev Calculates price impact from a RouteHop's pool reserves
    function _calculatePriceImpact(
        RouteHop memory hop,
        address tokenIn,
        uint256 amountIn,
        uint256 expectedOut
    ) private view returns (uint256 priceImpact) {
        (uint112 r0, uint112 r1,) = IUniswapV2Pair(hop.pool).getReserves();
        address t0 = IUniswapV2Pair(hop.pool).token0();
        address t1 = IUniswapV2Pair(hop.pool).token1();

        uint8 dec0 = _getDecimalsStatic(t0);
        uint8 dec1 = _getDecimalsStatic(t1);

        uint8 decIn  = tokenIn == t0 ? dec0 : dec1;
        uint8 decOut = tokenIn == t0 ? dec1 : dec0;

        uint256 rInNorm  = tokenIn == t0
            ? _normalizeReserve(r0, dec0) : _normalizeReserve(r1, dec1);
        uint256 rOutNorm = tokenIn == t0
            ? _normalizeReserve(r1, dec1) : _normalizeReserve(r0, dec0);

        if (rInNorm == 0 || rOutNorm == 0) return 0;

        uint256 amountInNorm  = _normalizeAmount(amountIn,    decIn);
        uint256 amountOutNorm = _normalizeAmount(expectedOut, decOut);

        if (amountInNorm == 0 || amountOutNorm == 0) return 0;

        uint256 executionRatio = FullMath.mulDiv(
            amountOutNorm * rInNorm,
            1e18,
            amountInNorm * rOutNorm
        );

        if (executionRatio >= 1e18) return 0;
        priceImpact = FullMath.mulDiv(1e18 - executionRatio, BPS_DENOMINATOR, 1e18);
    }

    /// @dev Computes composite routing score: higher output, higher liquidity, lower impact = better
    function _computePathScore(
        uint256 output,
        uint256 liquidity,
        uint256 impact
    ) private view returns (uint256 score) {
        if (output == 0) return 0;

        uint256 impactFactor   = SCORE_PRECISION + (impact * SCORE_PRECISION / BPS_DENOMINATOR);
        uint256 liquidityFactor;

        if (liquidity >= minPoolLiquidity) {
            liquidityFactor = SCORE_PRECISION;
        } else {
            liquidityFactor = FullMath.mulDiv(liquidity, SCORE_PRECISION, minPoolLiquidity);
        }

        uint256 numerator = FullMath.mulDiv(output, liquidityFactor, SCORE_PRECISION);
        score = FullMath.mulDiv(numerator, SCORE_PRECISION, impactFactor);
    }

    /// @dev Returns geometric mean liquidity for a pool, normalized to 18 decimals
    function _getPoolLiquidity(address pair) private view returns (bool success, uint256 liquidity) {
        (uint112 r0, uint112 r1, address t0, address t1) = _getPairReservesAndTokens(pair);
        if (r0 == 0 || r1 == 0) return (false, 0);

        uint8 dec0 = _getDecimalsStatic(t0);
        uint8 dec1 = _getDecimalsStatic(t1);

        uint256 r0Norm = _normalizeReserve(r0, dec0);
        uint256 r1Norm = _normalizeReserve(r1, dec1);

        liquidity = FixedPointMath.sqrt(r0Norm) * FixedPointMath.sqrt(r1Norm);
        if (liquidity == 0) return (false, 0);
        return (true, liquidity);
    }

    /// @dev Fetches and caches token decimals (state-mutating)
    function _getDecimals(address token) private returns (uint8 decimals) {
        if (_hasDecimalsCached[token]) return _tokenDecimals[token];
        try IERC20Metadata(token).decimals() returns (uint8 d) {
            _tokenDecimals[token]    = d;
            _hasDecimalsCached[token] = true;
            return d;
        } catch {
            return 18;
        }
    }

    /// @dev Fetches token decimals without state mutation (view-safe)
    function _getDecimalsStatic(address token) private view returns (uint8 decimals) {
        if (_hasDecimalsCached[token]) return _tokenDecimals[token];
        try IERC20Metadata(token).decimals() returns (uint8 d) { return d; }
        catch { return 18; }
    }

    /// @dev Normalizes raw reserve to 18-decimal precision
    function _normalizeReserve(uint256 rawReserve, uint8 decimals) private pure returns (uint256 normalized) {
        if (decimals <= 18) normalized = rawReserve * (10 ** (18 - decimals));
        else                normalized = rawReserve / (10 ** (decimals - 18));
    }

    /// @dev Normalizes token amount to 18-decimal precision
    function _normalizeAmount(uint256 amount, uint8 decimals) private pure returns (uint256 normalized) {
        if (decimals == 18) return amount;
        if (decimals  > 18) return amount / (10 ** (decimals - 18));
        return amount * (10 ** (18 - decimals));
    }

    /// @dev Safely calls factory.getPair, returns address(0) on revert
    function _getPairFromFactory(
        address factory,
        address tokenA,
        address tokenB
    ) private view returns (address pair) {
        if (factory.code.length == 0) return address(0);
        try IUniswapV2Factory(factory).getPair(tokenA, tokenB) returns (address p) { return p; }
        catch { return address(0); }
    }

    /// @notice Constructs a RouteHop with per-factory fee lookup
    /// @dev    feeNumerator/feeDenominator fall back to DEFAULT values if unset.
    ///         These fee values are encoded into the path and used during both
    ///         quote chaining (_quoteV2Swap) and execution (_calculateSwapOutput).
    /// @param pool     Pool address
    /// @param tokenOut Output token of this hop (always ERC20, never address(0))
    /// @param factory  Factory that deployed pool
    /// @return hop     Populated RouteHop struct
    function _buildHop(
        address pool,
        address tokenOut,
        address factory
    ) private view returns (RouteHop memory hop) {
        uint16 feeNum = factoryFeeNumerator[factory];
        uint16 feeDen = factoryFeeDenominator[factory];
        if (feeNum == 0) feeNum = DEFAULT_FEE_NUMERATOR;
        if (feeDen == 0) feeDen = DEFAULT_FEE_DENOMINATOR;
        hop = RouteHop({
            pool:             pool,
            tokenOut:         tokenOut,
            v2FeeNumerator:   feeNum,
            v2FeeDenominator: feeDen,
            factory:          factory
        });
    }

    // ADMIN: FACTORY MANAGEMENT

    /// @notice Sets whitelist status for a single factory
    /// @dev    Adds to allWhitelistedFactories on enable, removes on disable.
    /// @param factory Factory address
    /// @param status  True to whitelist, false to remove
    function setFactoryStatus(address factory, bool status) external onlyOwner {
        if (factory == address(0)) revert ZeroAddress();
        bool wasWhitelisted = isWhitelistedFactory[factory];
        isWhitelistedFactory[factory] = status;

        if (status && !wasWhitelisted) {
            allWhitelistedFactories.push(factory);
            emit FactoryAddedToRegistry(factory);
        }

        if (!status && wasWhitelisted) {
            uint256 len = allWhitelistedFactories.length;
            for (uint256 i = 0; i < len; i++) {
                if (allWhitelistedFactories[i] == factory) {
                    allWhitelistedFactories[i] = allWhitelistedFactories[len - 1];
                    allWhitelistedFactories.pop();
                    break;
                }
            }
        }

        emit FactoryStatusUpdated(factory, status);
    }

    /// @notice Sets whitelist status for multiple factories in one transaction
    /// @param factories Array of factory addresses
    /// @param status    True to whitelist, false to remove
    function batchSetFactoryStatus(address[] calldata factories, bool status) external onlyOwner {
        for (uint256 i = 0; i < factories.length; i++) {
            if (factories[i] == address(0)) revert ZeroAddress();
            bool wasWhitelisted = isWhitelistedFactory[factories[i]];
            isWhitelistedFactory[factories[i]] = status;

            if (status && !wasWhitelisted) {
                allWhitelistedFactories.push(factories[i]);
                emit FactoryAddedToRegistry(factories[i]);
            }

            if (!status && wasWhitelisted) {
                uint256 len = allWhitelistedFactories.length;
                for (uint256 j = 0; j < len; j++) {
                    if (allWhitelistedFactories[j] == factories[i]) {
                        allWhitelistedFactories[j] = allWhitelistedFactories[len - 1];
                        allWhitelistedFactories.pop();
                        len--;
                        break;
                    }
                }
            }

            emit FactoryStatusUpdated(factories[i], status);
        }
    }

    /// @notice Configures per-factory swap fee for accurate quote and execution alignment
    /// @dev    feeNumerator must be < feeDenominator (e.g. 9970/10000 = 0.30% fee).
    ///         These values propagate through _buildHop → path encoding →
    ///         _quoteV2Swap and _calculateSwapOutput, ensuring K-invariant consistency.
    /// @param factory       Factory address to configure
    /// @param feeNumerator  Fee complement numerator (e.g. 9970 for 0.30% swap fee)
    /// @param feeDenominator Fee denominator (typically 10000)
    function setFactoryFee(
        address factory,
        uint16 feeNumerator,
        uint16 feeDenominator
    ) external onlyOwner {
        if (factory == address(0)) revert ZeroAddress();
        if (feeNumerator == 0 || feeDenominator == 0 || feeNumerator >= feeDenominator)
            revert InvalidBasisPoints();
        factoryFeeNumerator[factory]   = feeNumerator;
        factoryFeeDenominator[factory] = feeDenominator;
        emit FactoryFeeSet(factory, feeNumerator, feeDenominator);
    }

    // ADMIN: ROUTING CONFIGURATION

    /// @notice Sets list of intermediate tokens for 2-hop route discovery
    /// @dev    Deduplicates input. Maximum MAX_COMMON_TOKENS entries.
    /// @param tokens Array of intermediate token addresses
    function setCommonTokens(address[] calldata tokens) external onlyOwner {
        if (tokens.length > MAX_COMMON_TOKENS) revert TooManyHops(tokens.length, MAX_COMMON_TOKENS);

        address[] memory uniqueTokens = new address[](tokens.length);
        uint256 uniqueCount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == address(0)) revert ZeroAddress();
            bool isDuplicate = false;
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueTokens[j] == tokens[i]) { isDuplicate = true; break; }
            }
            if (!isDuplicate) uniqueTokens[uniqueCount++] = tokens[i];
        }

        delete commonTokens;
        for (uint256 i = 0; i < uniqueCount; i++) commonTokens.push(uniqueTokens[i]);

        emit CommonTokensSet(uniqueTokens);
    }

    /// @notice Activates or deactivates the circuit breaker (halts all swaps)
    /// @param active True to halt swaps, false to resume
    function setCircuitBreaker(bool active) external onlyOwner {
        isCircuitBreakerActive = active;
        emit CircuitBreakerTriggered(active);
    }

    /// @notice Sets minimum pool liquidity threshold for route eligibility
    /// @param threshold Minimum geometric mean liquidity (18 decimals)
    function setMinPoolLiquidity(uint256 threshold) external onlyOwner {
        minPoolLiquidity = threshold;
    }

    /// @notice Sets protocol fee rate in basis points
    /// @dev    Maximum MAX_PROTOCOL_FEE (100 bps = 1%)
    /// @param newRate New fee rate in basis points
    function setProtocolFeeRate(uint256 newRate) external onlyOwner {
        if (newRate > MAX_PROTOCOL_FEE) revert InvalidBasisPoints();
        uint256 old = protocolFeeRate;
        protocolFeeRate = newRate;
        emit FeeRateAdjusted(old, newRate);
    }

    /// @notice Sets maximum allowed price impact for route eligibility
    /// @dev    Hard capped at ABSOLUTE_MAX_IMPACT (3000 bps = 30%)
    /// @param newMaxImpact New maximum price impact in basis points
    function setMaxPriceImpact(uint256 newMaxImpact) external onlyOwner {
        if (newMaxImpact > ABSOLUTE_MAX_IMPACT) revert InvalidBasisPoints();
        maxPriceImpact = newMaxImpact;
    }

    /// @notice Sets the primary factory used as fallback when no factories specified
    /// @param factory Primary factory address
    function setPrimaryFactory(address factory) external onlyOwner {
        address old = primaryFactory;
        primaryFactory = factory;
        emit PrimaryFactoryUpdated(old, factory);
    }

    /// @notice Sets default treasury address for protocol fee collection
    /// @param treasury Treasury address
    function setDefaultTreasury(address treasury) external onlyOwner {
        defaultTreasury = treasury;
    }

    /// @notice Sets default integrator address for fee split
    /// @param integrator Integrator address
    function setDefaultIntegrator(address integrator) external onlyOwner {
        defaultIntegrator = integrator;
    }

    // ADMIN: EMERGENCY

    /// @notice Withdraws stuck tokens or wrapped native from the aggregator contract
    /// @dev    Owner-only. Caps withdrawal at available balance to prevent revert.
    /// @param token     Token to withdraw (address(0) = WBNB)
    /// @param recipient Destination address
    /// @param amount    Amount to withdraw
    function emergencyWithdraw(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        if (amount == 0)             revert ZeroAmount();

        if (token == address(0) || token == WRAPPED_NATIVE) {
            uint256 balance = IWrappedNative(WRAPPED_NATIVE).balanceOf(address(this));
            if (amount > balance) amount = balance;
            if (amount > 0) IWrappedNative(WRAPPED_NATIVE).transfer(recipient, amount);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (amount > balance) amount = balance;
            if (amount > 0) IERC20(token).safeTransfer(recipient, amount);
        }
    }

    // VIEW FUNCTIONS

    /// @notice Returns all intermediate tokens used for 2-hop routing
    function getCommonTokens() external view returns (address[] memory tokens) {
        return commonTokens;
    }

    /// @notice Returns all whitelisted factory addresses
    function getAllWhitelistedFactories() external view returns (address[] memory factories) {
        return allWhitelistedFactories;
    }

    /// @notice Returns current maximum price impact threshold
    function getMaxPriceImpact() external view returns (uint256 maxImpact) {
        return maxPriceImpact;
    }

    /// @notice Returns current circuit breaker state
    function getCircuitBreakerState() external view returns (bool active) {
        return isCircuitBreakerActive;
    }

    /// @notice Returns cached or live token decimals
    /// @param token Token address
    function getTokenDecimals(address token) external returns (uint8 decimals) {
        return _getDecimals(token);
    }

    /// @notice Returns current minimum pool liquidity threshold
    function getMinPoolLiquidity() external view returns (uint256 threshold) {
        return minPoolLiquidity;
    }

    /// @notice Returns current protocol fee rate in basis points
    function getProtocolFeeRate() external view returns (uint256 rate) {
        return protocolFeeRate;
    }

    /// @notice Returns configured fee parameters for a factory
    /// @param factory Factory address
    /// @return feeNumerator   Fee numerator (0 = not set, uses default)
    /// @return feeDenominator Fee denominator (0 = not set, uses default)
    function getFactoryFee(address factory)
        external view
        returns (uint16 feeNumerator, uint16 feeDenominator)
    {
        return (factoryFeeNumerator[factory], factoryFeeDenominator[factory]);
    }

    // MAX INPUT FOR POOL

    /// @notice Binary-searches maximum input amount that stays within target price impact
    /// @dev    Uses per-factory fee from factoryFeeNumerator/feeDenominator.
    ///         Runs 24 iterations of binary search for sufficient precision.
    /// @param tokenIn         Input token
    /// @param tokenOut        Output token
    /// @param factories       Factories to evaluate (empty = all whitelisted)
    /// @param targetImpactBps Target maximum price impact in basis points
    /// @return cappedAmountIn Maximum input respecting targetImpactBps
    /// @return bestPool       Pool used for computation
    /// @return expectedOut    Expected output at cappedAmountIn
    function maxInputForPool(
        address tokenIn,
        address tokenOut,
        address[] calldata factories,
        uint256 targetImpactBps
    ) external view returns (uint256 cappedAmountIn, address bestPool, uint256 expectedOut) {
        if (targetImpactBps > ABSOLUTE_MAX_IMPACT) revert InvalidBasisPoints();

        address tIn  = tokenIn  == address(0) ? WRAPPED_NATIVE : tokenIn;
        address tOut = tokenOut == address(0) ? WRAPPED_NATIVE : tokenOut;

        address[] memory resolvedFactories = _resolveFactoriesToMemory(factories);

        uint256 bestLiquidity   = 0;
        bestPool                = address(0);
        address bestFactory     = address(0);

        for (uint256 i = 0; i < resolvedFactories.length; ) {
            address factory = resolvedFactories[i];
            if (factory.code.length != 0 && isWhitelistedFactory[factory]) {
                address pair = _getPairFromFactory(factory, tIn, tOut);
                if (pair != address(0)) {
                    (bool ok, uint256 liq) = _getPoolLiquidity(pair);
                    if (ok && liq > bestLiquidity) {
                        bestLiquidity = liq;
                        bestPool      = pair;
                        bestFactory   = factory;
                    }
                }
            }
            unchecked { ++i; }
        }

        if (bestPool == address(0)) return (0, address(0), 0);

        uint16 feeNum = factoryFeeNumerator[bestFactory];
        uint16 feeDen = factoryFeeDenominator[bestFactory];
        if (feeNum == 0) feeNum = DEFAULT_FEE_NUMERATOR;
        if (feeDen == 0) feeDen = DEFAULT_FEE_DENOMINATOR;

        (uint112 r0, uint112 r1, address t0,) = _getPairReservesAndTokens(bestPool);
        uint256 rIn = tIn == t0 ? uint256(r0) : uint256(r1);

        uint256 lo   = 1;
        uint256 hi   = rIn;
        uint256 best = 0;
        uint256 bestOut = 0;

        for (uint256 iter = 0; iter < 24; ) {
            uint256 mid = (lo + hi) / 2;

            RouteHop memory tempHop = RouteHop({
                pool:             bestPool,
                tokenOut:         tOut,
                v2FeeNumerator:   feeNum,
                v2FeeDenominator: feeDen,
                factory:          bestFactory
            });

            uint256 out    = _quoteV2Swap(tempHop, tIn, mid);
            uint256 impact = _calculatePriceImpact(tempHop, tIn, mid, out);

            if (impact <= targetImpactBps) {
                best    = mid;
                bestOut = out;
                lo      = mid + 1;
            } else {
                hi = mid - 1;
            }

            unchecked { ++iter; }
        }

        return (best, bestPool, bestOut);
    }

    // RECEIVE

    /// @dev Accepts native BNB.
    receive() external payable {}
}

