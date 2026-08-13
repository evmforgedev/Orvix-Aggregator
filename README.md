<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 300" width="1200" height="300">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4A90D9;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#87CEEB;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#F5F5F5;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#2C3E50;stop-opacity:0.9" />
      <stop offset="100%" style="stop-color:#34495E;stop-opacity:0.7" />
    </linearGradient>
  </defs>
  
  <rect width="1200" height="300" fill="url(#grad1)" rx="8"/>
  
  <circle cx="100" cy="150" r="120" fill="white" opacity="0.1"/>
  <circle cx="1100" cy="150" r="100" fill="white" opacity="0.08"/>
  <circle cx="600" cy="50" r="80" fill="white" opacity="0.05"/>
  
  <text x="600" y="100" font-family="Inter, sans-serif" font-size="52" font-weight="700" fill="#1A237E" text-anchor="middle" letter-spacing="2">
    ORVIX AGGREGATOR
  </text>
  
  <text x="600" y="145" font-family="Inter, sans-serif" font-size="22" font-weight="500" fill="#2C3E50" text-anchor="middle" opacity="0.9">
    BNB Chain AMM V2 Traversal Router
  </text>
  
  <rect x="350" y="170" width="500" height="2" fill="#1A237E" opacity="0.3" rx="1"/>
  
  <text x="600" y="205" font-family="Inter, sans-serif" font-size="15" font-weight="400" fill="#34495E" text-anchor="middle" opacity="0.8">
    Multi-Factory Routing Infrastructure
  </text>
  
  <text x="600" y="235" font-family="Inter, sans-serif" font-size="13" font-weight="300" fill="#4A6FA5" text-anchor="middle" opacity="0.7">
    Deterministic Path Discovery | Intelligent Quoting | Efficient Swap Execution
  </text>
  
  <text x="600" y="265" font-family="Inter, sans-serif" font-size="11" font-weight="300" fill="#5B7FB5" text-anchor="middle" opacity="0.6">
    Developed by ORVIX Labs
  </text>
</svg>
```

ORVIX AGGREGATOR

BNB Chain AMM V2 Traversal Router

OrvixAggregator is a robust, multi-factory Automated Market Maker (AMM) V2 routing infrastructure designed for BNB Chain. Developed by ORVIX Labs, it facilitates deterministic path discovery, intelligent quoting, liquidity assessment, and efficient swap execution across multiple supported AMM V2 liquidity sources.

The contract is designed for integration by wallets, decentralized applications (dApps), trading interfaces, aggregators, and broader Web3 infrastructure.

---

Deployed Contracts

Network Contract
BNB Smart Chain Mainnet 0x524a8557005ADdf838c3e267ce43b9B7EBfcCfc7 📋
BNB Smart Chain Testnet 0xA4Bf191D53B880cA49F1ceD0C0C840378bdDef42 📋

---

Live Swap Test Interface

A lightweight swap interface is available for testing the deployed OrvixAggregator contract on BNB Chain.

Live Test Interface: https://orvix-frontend.vercel.app/

The interface is intended primarily for aggregator contract testing and integration validation.

Testing Interface: This frontend is provided as a testing and integration interface for the deployed OrvixAggregator contract. Always verify the selected network and transaction parameters before signing a transaction.

---

What You Can Test

· Wallet connection
· Token pair selection
· Aggregator quote requests
· Multi-factory route discovery
· Direct and multi-hop routing
· Expected output calculation
· Slippage protection
· Encoded route execution
· Native BNB / WBNB handling
· On-chain swap execution
· Transaction confirmation

---

Test Flow

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

Testnet USST Faucet

For testing swaps without requiring real assets, Orvix provides a test USST token on BNB Chain Testnet.

USST Contract: 0x0b826aFC12380Cd138ED9e7211631033fa51716F 📋

Token Metadata

Property Value
Name USST Stable Faucet
Symbol USST
Decimals 18
Faucet amount 7,000 USST
Cooldown 24 hours
Network BNB Smart Chain Testnet

---

How to Get USST

The USST contract contains a permissionless mint() faucet function.

Any wallet can call:

```solidity
mint()
```

If the wallet has not claimed during the previous 24-hour period, the contract mints:

7,000 USST directly to the caller.

Daily Limit

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

Faucet Functions

mint()

Claims the daily faucet allocation.

```solidity
function mint() external
```

A successful call mints exactly: 7,000 USST

If the address is still within its cooldown period, the transaction reverts with: CooldownActive(nextMintTime)

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
BTS 0xF504A700fe1eC44A565cd4b5a2f6c6f536b5FB98 📋
QWE 0x4321afcF7642695Ea017982823c6A8a58EfC9fE2 📋
PVT 0x24b20A51Fd93F1F303d93caFf353EE8ec4868ef8 📋
NTC 0xC6A18484d8d9FFA64F658616a1196da8f76B7d5a 📋
TRAV 0xE844E1201df67D3c4aAA5656b2296a775C9F844A 📋
OPH 0x63855c836594e6BD9814b882ADFf28546d74790A 📋

These tokens are intended for BNB Chain Testnet integration and swap testing.

---

Active Testnet AMM Factories

The current test environment uses three AMM V2-compatible factory sources.

AMM Factory Address
PancakeSwap V2 0x6725F303b657a9451d8BA641348b6761A6CC7a17 📋
Orvix Factory 0x234aC76EAd737BddA66ce8CBB2C535B1f6F21C3a 📋
DEX Factory 0xC8888677ffEDfe125C5994c11276EAf2A2b25D09 📋

The aggregator can evaluate liquidity across these configured factories during route discovery.

---

Testnet Testing Setup

A typical test session can be performed as follows:

```
1. Switch wallet to BNB Chain Testnet
              ↓
2. Obtain testnet BNB for gas
              ↓
3. Claim 7,000 USST from the faucet
              ↓
4. Open the Live Swap Test Interface
              ↓
5. Connect wallet
              ↓
6. Select USST and one of the active test tokens
              ↓
7. Request a quote
              ↓
8. Review discovered route
              ↓
9. Approve token spending
              ↓
10. Execute swap
              ↓
11. Verify transaction on-chain
```

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

Routing Details

The OrvixAggregator performs route discovery by assessing available liquidity pools across all configured AMM factories. When a quote request is made, the aggregator evaluates pool reserves, calculates expected outputs for direct and multi-hop routes, and selects the optimal path based on the following criteria:

· Available liquidity in each pool
· Expected output amount
· Price impact considerations
· Route efficiency
· Gas cost optimization

The Vercel test interface displays the discovered routes, showing which pools are used and their respective contributions to the final output. The aggregator assesses pool data on-chain, ensuring real-time accuracy of quotes and route selection.

---

Security & Testing Notes

This deployment is intended to provide a practical environment for testing aggregator routing and swap execution.

Before signing a transaction:

· Confirm the wallet is connected to BNB Chain Testnet when using test assets
· Verify the token addresses
· Verify the selected route
· Review the expected output
· Confirm the amountOutMin / slippage settings
· Verify the recipient address
· Never enter or expose a private key
· Do not assume testnet assets have monetary value

The USST faucet is specifically designed for testing and does not represent a production stablecoin.

---

Mainnet AMM Factories

The Mainnet deployment supports multiple AMM V2 liquidity sources.

AMM Factory Address
PancakeSwap V2 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73 📋
BiSwap 0x858E3312ed3A876947EA49d572A7C42DE08af7EE 📋
ApeSwap 0x0841BD0B734E4F5853f0dD8d7Ea041c241fb0Da6 📋
SushiSwap 0xc35DADB65012eC5796536bD9864eD8773aBc74C4 📋
MDEX 0x3CD1C46068dAEa5Ebb0d3f55F6915B10648062B8 📋
BabySwap 0x86407bEa2078ea5F5EB5A52B2caA963bC1F889DA 📋
BakerySwap 0x01bF7C66c6BD861915CdaaE475042d3c4BaE16A7 📋

---

Repository

Source code: https://github.com/evmforgedev/Orvix-Aggregator

The repository contains the standalone OrvixAggregator.sol implementation and documentation for the deployed contracts and test environment.

---

License

Copyright (c) 2026 ORVIX Labs.

This project is licensed under the MIT License. See the SPDX-License-Identifier in the source file.
