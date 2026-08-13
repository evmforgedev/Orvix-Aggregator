OrvixAggregator

BNB Chain AMM V2 Traversal Router

"OrvixAggregator" is a robust, multi-factory Automated Market Maker (AMM) V2 routing infrastructure designed for BNB Chain. Developed by ORVIX Labs, it facilitates deterministic path discovery, intelligent quoting, liquidity assessment, and efficient swap execution across multiple supported AMM V2 liquidity sources.

The contract is designed for integration by wallets, decentralized applications (dApps), trading interfaces, aggregators, and broader Web3 infrastructure.

---

Deployed Contracts

Network| Contract Address
BNB Smart Chain Mainnet| "0x524a8557005ADdf838c3e267ce43b9B7EBfcCfc7"
BNB Smart Chain Testnet| "0xA4Bf191D53B880cA49F1ceD0C0C840378bdDef42"

---

Supported Mainnet AMM Factories

The Mainnet deployment is designed to traverse multiple AMM V2-compatible liquidity sources.

AMM| Factory Address
PancakeSwap V2| "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"
BiSwap| "0x858E3312ed3A876947EA49d572A7C42DE08af7EE"
ApeSwap| "0x0841BD0B734E4F5853f0dD8d7Ea041c241fb0Da6"
SushiSwap| "0xc35DADB65012eC5796536bD9864eD8773aBc74C4"
MDEX| "0x3CD1C46068dAEa5Ebb0d3f55F6915B10648062B8"
BabySwap| "0x86407bEa2078ea5F5EB5A52B2caA963bC1F889DA"
BakerySwap| "0x01bF7C66c6BD861915CdaaE475042d3c4BaE16A7"

Factory addresses are configured through the contract's factory whitelist and are used as liquidity sources during route discovery.

---

Architecture

                         ┌──────────────────────┐
                         │     OrvixAggregator  │
                         └──────────┬───────────┘
                                    │
                     ┌──────────────┴──────────────┐
                     │       Route Discovery       │
                     └──────────────┬──────────────┘
                                    │
       ┌────────────┬───────────────┼───────────────┬────────────┐
       │            │               │               │            │
       ▼            ▼               ▼               ▼            ▼
  Pancake V2     BiSwap         ApeSwap        SushiSwap      MDEX
       │            │               │               │            │
       └────────────┴───────────────┼───────────────┴────────────┘
                                    │
                         ┌──────────▼──────────┐
                         │  Liquidity Scoring  │
                         │  + Price Impact     │
                         │  + Fee Calculation  │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │   Best Route        │
                         │   Determination     │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │  swapExactInput     │
                         └─────────────────────┘

The same routing architecture can evaluate liquidity across the configured factory whitelist rather than relying on a single AMM.

---

Key Features

Multi-Factory Routing

Aggregates liquidity discovery across multiple whitelisted AMM V2 factories, including:

- PancakeSwap V2
- BiSwap
- ApeSwap
- SushiSwap
- MDEX
- BabySwap
- BakerySwap

Factory support is controlled through the contract's whitelist.

Per-Factory Fee Support

Each factory can have its own configured fee parameters.

The router uses the configured fee numerator and denominator when calculating swap output and validating the route.

This allows different AMM implementations with different fee structures to participate in the same routing system.

Intelligent Path Discovery

The quoting engine evaluates:

- Direct single-hop routes.
- Multi-hop routes.
- Intermediate tokens configured through "commonTokens".
- Liquidity depth.
- Expected output.
- Estimated price impact.
- Factory-specific swap fees.

The highest-scoring valid route is returned to the caller.

Liquidity Scoring Engine

Candidate routes are evaluated using a composite scoring mechanism incorporating expected output, liquidity characteristics, and price-impact penalties.

This allows the router to compare multiple pools instead of selecting a route solely based on pool existence.

Price Impact Filtering

Routes exceeding the configured maximum price-impact threshold can be rejected during route evaluation.

This provides an additional protection layer against execution through severely illiquid pools.

Deterministic Route Encoding

Routing instructions are encoded into a compact binary representation.

[version: 1 byte]
[hopCount: 1 byte]
[RouteHop × N]

Each "RouteHop" occupies 64 bytes:

pool              20 bytes
tokenOut          20 bytes
v2FeeNumerator     2 bytes
v2FeeDenominator   2 bytes
factory            20 bytes

Total:

64 bytes per hop

The encoded route returned by "quoteExactInput" can subsequently be supplied to "swapExactInput".

Native BNB Handling

The router supports native BNB as an input or output asset.

Internally, native BNB is represented through the configured wrapped-native token during AMM interaction.

The path encoding uses the wrapped-native address rather than "address(0)".

Protocol Fee Split

The router supports a configurable protocol fee taken from the input amount.

The fee mechanism can distribute the configured protocol fee between:

- Protocol treasury.
- Integrating partner.

Circuit Breaker

An owner-controlled circuit breaker can halt swap activity in emergency situations.

---

Mainnet Liquidity Sources

The current Mainnet configuration includes seven AMM V2 factory sources:

PancakeSwap V2
BiSwap
ApeSwap
SushiSwap
MDEX
BabySwap
BakerySwap

This multi-source architecture allows "OrvixAggregator" to search for liquidity across different AMM ecosystems before selecting an execution route.

---

Workflow

1. Quote

The integration calls:

quoteExactInput(
    tokenIn,
    tokenOut,
    amountIn,
    factories,
    slippageBps
)

The quoting engine evaluates available liquidity across the selected factories.

The process includes:

1. Factory validation.
2. Pool discovery.
3. Direct-route evaluation.
4. Multi-hop route evaluation.
5. Factory-specific fee calculation.
6. Liquidity assessment.
7. Price-impact estimation.
8. Route scoring.
9. Best-route selection.
10. Binary path encoding.

The result contains the expected output and encoded route required for execution.

2. Execute

The integration supplies the returned route to:

swapExactInput(
    tokenIn,
    tokenOut,
    amountIn,
    amountOutMin,
    recipient,
    deadline,
    path,
    treasury,
    integrator
)

The contract then:

1. Validates the encoded route.
2. Validates hop continuity.
3. Validates factory whitelist status.
4. Validates pool existence.
5. Calculates and deducts protocol fees.
6. Handles native BNB/WBNB conversion.
7. Executes swaps hop-by-hop.
8. Validates final output against "amountOutMin".
9. Transfers or unwraps the final asset as required.

---

Contract Interface

User Functions

"quoteExactInput"

quoteExactInput(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    address[] calldata factories,
    uint256 slippageBps
)

Returns the optimal route, expected output, and encoded path.

Use "address(0)" to represent native BNB where supported by the interface.

"swapExactInput"

swapExactInput(
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

Executes the previously quoted route.

---

Diagnostic Functions

"assessPools"

assessPools(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    address[] calldata factories,
    bool rawMode
)

Evaluates candidate pools and returns diagnostic information including output estimates, liquidity metrics, scores, and failure reasons.

"maxInputForPool"

maxInputForPool(
    address tokenIn,
    address tokenOut,
    address[] calldata factories,
    uint256 targetImpactBps
)

Calculates the maximum input amount that can be routed while remaining within the specified price-impact threshold.

---

Administrative Functions

Administrative functionality is restricted to the contract owner.

Factory Management

setFactoryStatus(address factory, bool status)
batchSetFactoryStatus(...)

Controls which AMM factories are available for routing.

Factory Fee Configuration

setFactoryFee(
    address factory,
    uint16 feeNumerator,
    uint16 feeDenominator
)

Configures the fee parameters used for a specific factory.

Common Tokens

setCommonTokens(address[] calldata tokens)

Configures intermediate tokens used during multi-hop route discovery.

Protocol Fee

setProtocolFeeRate(uint256 newRate)

Updates the protocol fee rate subject to the contract's configured maximum.

Circuit Breaker

setCircuitBreaker(bool active)

Activates or deactivates the emergency swap circuit breaker.

Initialization

initialize(address treasury)

Initializes the deployment and configures the default treasury.

---

Security & Mathematics

The contract uses several mechanisms designed to make swap execution safer and mathematically consistent.

SafeERC20

Token transfers use OpenZeppelin "SafeERC20" to improve compatibility with ERC20 implementations that do not strictly follow the standard return-value behavior.

Full-Precision Mathematics

The routing and liquidity calculations use high-precision arithmetic where required to reduce overflow and rounding issues.

Reentrancy Protection

State-changing and swap execution paths use reentrancy protection.

Slippage Protection

The caller specifies "amountOutMin", ensuring that execution fails if the final received amount falls below the user's minimum acceptable output.

Deadline Protection

Swap execution accepts a deadline to prevent stale routes from being executed after their intended validity period.

---

Development

The contract is written in:

Solidity ^0.8.34

Build with Foundry:

forge build

Run tests:

forge test

For development environments, install the required dependencies before compilation.

---

Repository

Source code:

https://github.com/evmforgedev/Orvix-Aggregator

The repository intentionally focuses on the standalone "OrvixAggregator.sol" implementation.

---

Deployment Status

Network| Status
BNB Smart Chain Mainnet| Live
BNB Smart Chain Testnet| Live

Mainnet

0x524a8557005ADdf838c3e267ce43b9B7EBfcCfc7

Testnet

0xA4Bf191D53B880cA49F1ceD0C0C840378bdDef42

---

License

Copyright (c) 2026 ORVIX Labs.

This project is licensed under the MIT License. See the SPDX-License-Identifier in the source file.
