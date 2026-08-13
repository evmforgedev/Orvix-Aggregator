# OrvixAggregator

BNB Chain AMM V2 Traversal Router

"OrvixAggregator" is a robust, multi-factory Automated Market Maker (AMM) V2 routing infrastructure designed for BNB Chain. Developed by ORVIX Labs, it facilitates deterministic path discovery, intelligent quoting, liquidity assessment, and efficient swap execution across multiple supported AMM V2 liquidity sources.

The contract is designed for integration by wallets, decentralized applications (dApps), trading interfaces, aggregators, and broader Web3 infrastructure.

---

## Banner

```

+------------------------------------------------------------------+

|                                                                  |

|             O R V I X   A G G R E G A T O R                      |

|                                                                  |

|           BNB Chain · AMM V2 · Multi-Factory Router             |

|                                                                  |
+------------------------------------------------------------------+

```

---

## Deployed Contracts

| Network | Contract |
| :--- | :--- |
| BNB Smart Chain Mainnet | "0x524a8557005ADdf838c3e267ce43b9B7EBfcCfc7" |
| BNB Smart Chain Testnet | "0xA4Bf191D53B880cA49F1ceD0C0C840378bdDef42" |

---

## Live Swap Test Interface

A lightweight swap interface is available for testing the deployed "OrvixAggregator" contract on BNB Chain.

**Live Test Interface:**  
https://orvix-frontend.vercel.app/

The interface is intended primarily for aggregator contract testing and integration validation.

> **Testing Interface:** This frontend is provided as a testing and integration interface for the deployed "OrvixAggregator" contract. Always verify the selected network and transaction parameters before signing a transaction.

---

## What You Can Test

- Wallet connection
- Token pair selection
- Aggregator quote requests
- Multi-factory route discovery
- Direct and multi-hop routing
- Expected output calculation
- Slippage protection
- Encoded route execution
- Native BNB / WBNB handling
- On-chain swap execution
- Transaction confirmation

---

## Test Flow

```

Connect Wallet
↓
Select Input / Output Token
↓
Enter Amount
↓
Request Aggregator Quote
↓
Route Discovery
↓
Select Best Available Route
↓
Approve Token
↓
Execute swapExactInput()
↓
Verify On-Chain Result

```

---

## Testnet USST Faucet

For testing swaps without requiring real assets, Orvix provides a test USST token on BNB Chain Testnet.

**USST Contract**  
0x0b826aFC12380Cd138ED9e7211631033fa51716F

**Token metadata:**

| Property | Value |
| :--- | :--- |
| Name | USST Stable Faucet |
| Symbol | USST |
| Decimals | 18 |
| Faucet amount | 7,000 USST |
| Cooldown | 24 hours |
| Network | BNB Smart Chain Testnet |

---

## How to Get USST

The USST contract contains a permissionless `mint()` faucet function.

Any wallet can call:

```

mint()

```

If the wallet has not claimed during the previous 24-hour period, the contract mints:

```

7,000 USST

```

directly to the caller.

**Daily Limit**

The faucet is limited to one successful claim per address every 24 hours.

```

1 wallet
↓
7,000 USST
↓
24-hour cooldown
↓
Claim again

```

The cooldown is tracked independently for each wallet address.

There is no allowlist and no ownership check on the faucet claim function.

Bots and smart contracts are also permitted to call the faucet.

---

## Faucet Functions

**`mint()`**

Claims the daily faucet allocation.

```solidity
function mint() external
```

A successful call mints exactly:

```
7,000 USST
```

If the address is still within its cooldown period, the transaction reverts with:

```
CooldownActive(nextMintTime)
```

canMint(address user)

Checks whether an address can claim immediately.

```solidity
function canMint(address user) external view returns (bool)
```

nextMintTime(address user)

Returns the earliest timestamp at which the address can claim again.

```solidity
function nextMintTime(address user) external view returns (uint256)
```

---

Testnet Swap Tokens

The following test tokens currently have active liquidity available for aggregator testing.

Token Contract Address
BTS "0xF504A700fe1eC44A565cd4b5a2f6c6f536b5FB98"
QWE "0x4321afcF7642695Ea017982823c6A8a58EfC9fE2"
PVT "0x24b20A51Fd93F1F303d93caFf353EE8ec4868ef8"
NTC "0xC6A18484d8d9FFA64F658616a1196da8f76B7d5a"
TRAV "0xE844E1201df67D3c4aAA5656b2296a775C9F844A"
OPH "0x63855c836594e6BD9814b882ADFf28546d74790A"

These tokens are intended for BNB Chain Testnet integration and swap testing.

---

Active Testnet AMM Factories

The current test environment uses three AMM V2-compatible factory sources.

AMM Factory Address
PancakeSwap V2 "0x6725F303b657a9451d8BA641348b6761A6CC7a17"
Orvix Factory "0x234aC76EAd737BddA66ce8CBB2C535B1f6F21C3a"
DEX Factory "0xC8888677ffEDfe125C5994c11276EAf2A2b25D09"

The aggregator can evaluate liquidity across these configured factories during route discovery.

---

Testnet Testing Setup

A typical test session can be performed as follows:

1. Switch wallet to BNB Chain Testnet
2. Obtain testnet BNB for gas
3. Claim 7,000 USST from the faucet
4. Open the Live Swap Test Interface
5. Connect wallet
6. Select USST and one of the active test tokens
7. Request a quote
8. Review discovered route
9. Approve token spending
10. Execute swap
11. Verify transaction on-chain

The same flow can be used to test direct routes and, where available, multi-hop routes through the configured AMM factories.

---

Example Test Pair

USST can be used as the primary test asset.

```
USST
  ↓
Aggregator
  ↓
PancakeSwap V2 / Orvix Factory / DEX Factory
  ↓
BTS / QWE / PVT / NTC / TRAV / OPH
```

The actual route selected by the aggregator depends on pool availability, liquidity, configured fees, expected output, and route scoring.

---

Routing Output on Vercel Interface

The Vercel-hosted test interface displays routing information based on pool assessments. When a user requests a quote, the interface queries the OrvixAggregator contract to evaluate all available liquidity pools across the configured factories.

The output shows:

· Available pools: Lists all AMM V2 pools that contain the selected token pair, including direct pools and intermediate token pools for multi-hop routes.
· Liquidity depth: Displays the reserve amounts in each pool, indicating the available liquidity for the swap amount.
· Price impact: Calculates the estimated price impact based on the swap size and pool reserves.
· Route paths: Shows the proposed route path, including intermediate tokens for multi-hop swaps.
· Expected output: Provides the estimated output amount for each potential route.
· Best route selection: Highlights the route that offers the highest expected output after considering fees and slippage.

The interface performs these assessments by simulating swap executions across the evaluated pools and comparing the results to recommend the optimal route.

---

Security & Testing Notes

This deployment is intended to provide a practical environment for testing aggregator routing and swap execution.

Before signing a transaction:

· Confirm the wallet is connected to BNB Chain Testnet when using test assets.
· Verify the token addresses.
· Verify the selected route.
· Review the expected output.
· Confirm the amountOutMin / slippage settings.
· Verify the recipient address.
· Never enter or expose a private key.
· Do not assume testnet assets have monetary value.

The USST faucet is specifically designed for testing and does not represent a production stablecoin.

---

Mainnet AMM Factories

The Mainnet deployment supports multiple AMM V2 liquidity sources.

AMM Factory Address
PancakeSwap V2 "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"
BiSwap "0x858E3312ed3A876947EA49d572A7C42DE08af7EE"
ApeSwap "0x0841BD0B734E4F5853f0dD8d7Ea041c241fb0Da6"
SushiSwap "0xc35DADB65012eC5796536bD9864eD8773aBc74C4"
MDEX "0x3CD1C46068dAEa5Ebb0d3f55F6915B10648062B8"
BabySwap "0x86407bEa2078ea5F5EB5A52B2caA963bC1F889DA"
BakerySwap "0x01bF7C66c6BD861915CdaaE475042d3c4BaE16A7"

---

Repository

Source code:
https://github.com/evmforgedev/Orvix-Aggregator

The repository contains the standalone OrvixAggregator.sol implementation and documentation for the deployed contracts and test environment.

---

License

Copyright (c) 2026 ORVIX Labs.

This project is licensed under the MIT License. See the SPDX-License-Identifier in the source file.
