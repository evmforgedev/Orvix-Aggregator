OrvixAggregator

BNB Chain AMM V2 Traversal Router

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 200" width="1000" height="200">
  <defs>
    <linearGradient id="skyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4A90D9;stop-opacity:1" />
      <stop offset="30%" style="stop-color:#87CEEB;stop-opacity:1" />
      <stop offset="60%" style="stop-color:#E8F4FD;stop-opacity:1" />
      <stop offset="85%" style="stop-color:#F0F4F8;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#DDE2E8;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="textGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#1A365D;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#2B6CB0;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#3182CE;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="subGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#4A5568;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#718096;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#A0AEC0;stop-opacity:1" />
    </linearGradient>
    <filter id="shadow" x="-5%" y="-5%" width="110%" height="110%">
      <feDropShadow dx="1" dy="2" stdDeviation="2" flood-opacity="0.15"/>
    </filter>
  </defs>

  <rect width="1000" height="200" rx="12" fill="url(#skyGrad)" stroke="#C5D5E4" stroke-width="1.5"/>

  <circle cx="820" cy="40" r="18" fill="#E8F4FD" opacity="0.6"/>
  <circle cx="870" cy="25" r="12" fill="#F0F4F8" opacity="0.5"/>
  <circle cx="750" cy="30" r="10" fill="#DDE2E8" opacity="0.4"/>

  <path d="M 50 160 Q 200 130 350 150 T 600 140 T 850 155 L 900 160" fill="none" stroke="#B0C4DE" stroke-width="1.5" opacity="0.4"/>
  <path d="M 60 170 Q 250 145 400 165 T 650 155 T 880 168" fill="none" stroke="#C5D5E4" stroke-width="1" opacity="0.3"/>

<text x="500" y="75" font-family="'Segoe UI', Arial, sans-serif" font-size="52" font-weight="700" fill="url(#textGrad)" text-anchor="middle" filter="url(#shadow)">OrvixAggregator</text>

<text x="500" y="115" font-family="'Segoe UI', Arial, sans-serif" font-size="22" font-weight="500" fill="url(#subGrad)" text-anchor="middle" letter-spacing="1.5">BNB Chain AMM V2 Traversal Router</text>

  <rect x="330" y="140" width="340" height="32" rx="16" fill="#1A365D" opacity="0.85"/>
  <text x="500" y="162" font-family="'Segoe UI', Arial, sans-serif" font-size="14" font-weight="400" fill="#E8F4FD" text-anchor="middle" letter-spacing="0.8">ORVIX Labs 2026 - Multi-Factory Routing Infrastructure</text>

  <circle cx="70" cy="160" r="6" fill="#4A90D9" opacity="0.3"/>
  <circle cx="90" cy="150" r="4" fill="#87CEEB" opacity="0.25"/>
  <circle cx="55" cy="145" r="3" fill="#B0C4DE" opacity="0.2"/>

  <circle cx="910" cy="155" r="8" fill="#4A90D9" opacity="0.2"/>
  <circle cx="930" cy="165" r="5" fill="#87CEEB" opacity="0.15"/>
  <circle cx="945" cy="145" r="4" fill="#B0C4DE" opacity="0.15"/>
</svg>

---

Overview

OrvixAggregator is a robust, multi-factory Automated Market Maker (AMM) V2 routing infrastructure designed for BNB Chain. Developed by ORVIX Labs, it facilitates deterministic path discovery, intelligent quoting, liquidity assessment, and efficient swap execution across multiple supported AMM V2 liquidity sources.

The contract is designed for integration by wallets, decentralized applications (dApps), trading interfaces, aggregators, and broader Web3 infrastructure.

---

Deployed Contracts

Network Contract
BNB Smart Chain Mainnet 0x524a8557005ADdf838c3e267ce43b9B7EBfcCfc7
BNB Smart Chain Testnet 0xA4Bf191D53B880cA49F1ceD0C0C840378bdDef42

---

Live Swap Test Interface

A lightweight swap interface is available for testing the deployed OrvixAggregator contract on BNB Chain.

Live Test Interface:
https://orvix-frontend.vercel.app/

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

Routing and Quote Output

When requesting a quote through the aggregator, the system evaluates liquidity across all configured AMM factories and returns a comprehensive route assessment.

Quote Output Components

The aggregator's quote response includes the following information derived from pool analysis:

Component Description
Route Path The sequence of token addresses and pools traversed to complete the swap
Expected Output The calculated minimum amount of output token expected from the swap
Pool Assessments Liquidity depth and pricing evaluation from each AMM factory consulted
Gas Estimation Estimated gas cost for executing the selected route
Slippage Parameters Maximum acceptable deviation from the quoted output

Route Discovery Process

1. Factory Enumeration - The aggregator queries all configured AMM factories for available pools
2. Pool Assessment - Each pool is evaluated for liquidity depth, price impact, and swap efficiency
3. Path Construction - Direct and multi-hop paths are constructed using available pools
4. Route Scoring - Each possible route is scored based on expected output and gas efficiency
5. Quote Generation - The best available route is returned with full execution parameters

Pool Assessment Criteria

The aggregator evaluates each pool based on:

· Liquidity Depth - Total reserves and available volume
· Price Impact - Expected slippage for the requested trade size
· Swap Efficiency - Fee structure and routing overhead
· Multi-Hop Viability - Compatibility with intermediate token pairs

The output displayed in the test interface represents the optimal route discovered during this assessment process. The interface shows the complete route path, expected output, and relevant execution parameters for the selected swap.

---

Testnet USST Faucet

For testing swaps without requiring real assets, Orvix provides a test USST token on BNB Chain Testnet.

USST Contract

0x0b826aFC12380Cd138ED9e7211631033fa51716F

Property Value
Name USST Stable Faucet
Symbol USST
Decimals 18
Faucet amount 7,000 USST
Cooldown 24 hours
Network BNB Smart Chain Testnet

How to Get USST

The USST contract contains a permissionless mint() faucet function. Any wallet can call:

```
mint()
```

If the wallet has not claimed during the previous 24-hour period, the contract mints 7,000 USST directly to the caller.

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

The cooldown is tracked independently for each wallet address. There is no allowlist and no ownership check on the faucet claim function. Bots and smart contracts are also permitted to call the faucet.

---

Faucet Functions

mint()

Claims the daily faucet allocation.

```solidity
function mint() external
```

A successful call mints exactly 7,000 USST. If the address is still within its cooldown period, the transaction reverts with CooldownActive(nextMintTime).

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
BTS 0xF504A700fe1eC44A565cd4b5a2f6c6f536b5FB98
QWE 0x4321afcF7642695Ea017982823c6A8a58EfC9fE2
PVT 0x24b20A51Fd93F1F303d93caFf353EE8ec4868ef8
NTC 0xC6A18484d8d9FFA64F658616a1196da8f76B7d5a
TRAV 0xE844E1201df67D3c4aAA5656b2296a775C9F844A
OPH 0x63855c836594e6BD9814b882ADFf28546d74790A

These tokens are intended for BNB Chain Testnet integration and swap testing.

---

Active Testnet AMM Factories

The current test environment uses three AMM V2-compatible factory sources.

AMM Factory Address
PancakeSwap V2 0x6725F303b657a9451d8BA641348b6761A6CC7a17
Orvix Factory 0x234aC76EAd737BddA66ce8CBB2C535B1f6F21C3a
DEX Factory 0xC8888677ffEDfe125C5994c11276EAf2A2b25D09

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

Security and Testing Notes

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
PancakeSwap V2 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
BiSwap 0x858E3312ed3A876947EA49d572A7C42DE08af7EE
ApeSwap 0x0841BD0B734E4F5853f0dD8d7Ea041c241fb0Da6
SushiSwap 0xc35DADB65012eC5796536bD9864eD8773aBc74C4
MDEX 0x3CD1C46068dAEa5Ebb0d3f55F6915B10648062B8
BabySwap 0x86407bEa2078ea5F5EB5A52B2caA963bC1F889DA
BakerySwap 0x01bF7C66c6BD861915CdaaE475042d3c4BaE16A7

---

Repository

Source code:
https://github.com/evmforgedev/Orvix-Aggregator

The repository contains the standalone OrvixAggregator.sol implementation and documentation for the deployed contracts and test environment.

---

License

Copyright (c) 2026 ORVIX Labs.

This project is licensed under the MIT License. See the SPDX-License-Identifier in the source file.
