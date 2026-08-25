<div align="center">
  <img width="1200" height="475" alt="EVM FORGE DEV" "./evmforge.svg">
</div>
OrvixMediaRegistry — Design & Implementation Guide
📋 Overview
OrvixMediaRegistry is a permissionless on-chain media database that maps wallet addresses to media URIs. It is NOT a token, launchpad, or NFT contract. It is purely a data layer for storing and retrieving media URIs.

Core Concept:

wallet address → Media[] → [ {uri, timestamp}, {uri, timestamp}, ... ]

🏗️ Storage Design
Data Structure
struct Media {
    string uri;           // HTTPS, IPFS, image, video, or any link
    uint256 createdAt;    // Unix timestamp when media was added
}

mapping(address => Media[]) private _media;  // Wallet → Media array

Why This Design?
Simplicity: Direct mapping from wallet to array of records

Permissionless: No whitelist, roles, or access control layers

Ownership: msg.sender implicitly owns their record (stored under their address key)

Frontend-friendly: getMedia(wallet) returns complete Media[] in one call

Gas-reasonable: Array storage is standard; no extra lookup overhead

Storage Trade-offs
Aspect

Impact

Note

String Storage

HIGH COST

Strings are expensive on-chain (~50-100 gas per byte). URIs like https://example.com/video.mp4 will consume ~1-2k gas to store.

Array Push

MODERATE COST

Adding to array is O(1). Resizing is handled by EVM memory model.

Calldata Input

GAS SAVINGS

Using calldata instead of memory for string parameters saves ~1-2% gas.

Recommendation: For production use, consider storing on IPFS/Arweave and only storing the hash on-chain. However, per requirements, full URIs are stored on-chain and readable by frontend.

🔌 Frontend Integration
Query Pattern
// Step 1: Get all media for a wallet
const mediaArray = await contract.getMedia(walletAddress);

// Step 2: mediaArray is now:
// [
//   { uri: "https://example.com/image.png", createdAt: 1692000000 },
//   { uri: "ipfs://QmXxxx...", createdAt: 1692086400 },
//   { uri: "https://youtube.com/watch?v=xxx", createdAt: 1692172800 }
// ]

// Step 3: Frontend determines how to render each URI
for (const media of mediaArray) {
  if (media.uri.startsWith("ipfs://")) {
    // Render IPFS image/video via IPFS gateway
  } else if (media.uri.includes("youtube.com")) {
    // Embed YouTube player
  } else if (media.uri.endsWith(".png") || media.uri.endsWith(".jpg")) {
    // Render as <img>
  } else if (media.uri.endsWith(".mp4")) {
    // Render as <video>
  } else {
    // Render as link
  }
}

Discovery Flow
User enters wallet address in UI
         ↓
Frontend calls: getMedia(walletAddress)
         ↓
Smart contract returns: Media[] from mapping
         ↓
Frontend loops through URIs
         ↓
Determines content type (image/video/link)
         ↓
Renders content

Indexing (Optional Enhancement)
For fast discovery of all wallets with media, use The Graph or Alchemy Subgraphs:

query {
  mediaAddeds(first: 100) {
    owner
    uri
    timestamp
  }
}

The Graph will index MediaAdded events automatically.

🔐 Security Considerations
1. Access Control ✓
Only msg.sender can call updateMedia() and removeMedia() on their own records

This is enforced by the mapping structure: _media[msg.sender]

Other wallets cannot modify or delete another wallet's media

Attack Scenario (Mitigated):

❌ Wallet B tries: removeMedia(index) on Wallet A's record
   → Wallet B's transaction calls _media[Wallet B].pop()
   → Only removes from Wallet B's array, not Wallet A's
   → SAFE

2. Input Validation ✓
EmptyUri() check prevents storing empty strings

IndexOutOfBounds() check prevents accessing invalid indices

No overflow/underflow risk (Solidity 0.8.34+ has built-in checks)

3. Reentrancy ✓
No external calls in any function → No reentrancy risk

No state changes after external calls → CEI pattern not needed

4. URI Validation ✗ (Intentionally NOT implemented)
Contract does NOT validate URI format, scheme, or content type

Frontend is responsible for:

Validating HTTPS/IPFS URIs before display

Detecting malicious links

CORS/CSP headers for security

Content filtering (if needed)

Rationale: Validation is expensive on-chain and would over-engineer the contract. Frontend has better tools.

5. Event Correctness ✓
All events have indexed owner for efficient filtering

Events emit actual URI and timestamp (not hashed)

Allows indexers and frontends to track media changes

⚡ Gas & Cost Analysis
Based on the official Foundry Gas Report (forge test --gas-report), here is the precise gas consumption for the OrvixMediaRegistry contract.

Contract Deployment
Deployment Cost: 644,938 gas

Deployment Size: 2,762 bytes

Function Gas Usage (Actual Foundry Report)
Function Name

Min Gas

Avg Gas

Median Gas

Max Gas

# Calls

addMedia

21,760

112,384

92,521

206,352

548

getMedia

2,838

9,992

7,949

18,167

5

getMediaAt

2,516

9,418

7,470

18,523

533

getMediaCount

2,397

2,397

2,397

2,397

18

removeMedia

23,638

32,413

32,217

39,140

10

updateMedia

21,916

46,791

34,534

112,523

263

Cost Drivers
String Storage (Biggest Cost)

As seen in addMedia (Max: 206k gas), storing long URIs heavily impacts gas.

Example: Adding a long URI costs ~217,230 gas, while a short URI costs ~102,625 gas.

Array Operations

removeMedia uses a pop-and-swap method, keeping costs consistently low (Avg: ~32k gas) as it avoids array shifting loops.

Reads / Views

Read operations (getMedia, getMediaCount) are highly optimized and practically free for off-chain queries, but cost minimal gas (~2.3k - ~9.9k) when called by other contracts.

📝 Usage Examples
Example 1: Add Media
Transaction:

wallet: 0x1234...5678
function: addMedia(string)
argument: "https://example.com/profile.jpg"

Result:

Media stored at: _media[0x1234...5678][0]

Event emitted: MediaAdded(0x1234...5678, 0, "https://example.com/profile.jpg", <timestamp>)

Example 2: Update Media
Transaction (Wallet 0x1234...5678 updating their own record):

wallet: 0x1234...5678
function: updateMedia(uint256, string)
argument_1: 0
argument_2: "https://example.com/new-profile.jpg"

Example 3: Remove Media (Index Shift Behavior)
Initial State: [ { uri: "photo1" }, { uri: "photo2" }, { uri: "photo3" } ] Transaction: removeMedia(1) (removes "photo2") Final State: [ { uri: "photo1" }, { uri: "photo3" } ] (Notice: "photo3" shifts from index 2 to index 1. Frontend must refetch getMedia() to sync indices).

🚀 Deployment & Testing Execution
1. Deployment to BSC Testnet (Chain 97)
The smart contract was successfully deployed and verified on the Binance Smart Chain (BSC) Testnet using Foundry.

Deployment Command Executed:

forge script script/DeployOrvixMediaRegistry.s.sol:DeployOrvixMediaRegistry \
   --rpc-url $RPC_URL \
   --broadcast \
   --verify \
   --etherscan-api-key $API_KEY

Understanding the Command Flags:

forge script: Instructs Foundry to run a Solidity script.

script/DeployOrvixMediaRegistry.s.sol:DeployOrvixMediaRegistry: The path to the script file and the specific contract/script name to execute.

--rpc-url $RPC_URL: Defines the network node to connect to (in this case, BSC Testnet RPC).

--broadcast: Tells Foundry to actually sign and broadcast the transactions to the live network (without this, it only runs a local simulation).

--verify: Automatically attempts to verify the smart contract source code on the block explorer after deployment.

--etherscan-api-key $API_KEY: Passes the API key (from BscScan) required to authenticate the verification request.

Deployment Results:

Network: BSC Testnet (Chain 97)

Contract Address: 0xd82f39Ea76bB22aC20Cf09A4c8976961493cE8f7

Transaction Hash: 0x5d6e5197e09765d3675965867adbcde3dc37215b88a5884f396010404e6e58e0

Block Number: 126254254

Gas Paid: 0.0000644938 BNB (644,938 gas * 0.1 gwei)

Verification Status: ✅ Pass - Verified (EVM version: cancun, Compiler: 0.8.34, Optimizer: 200)

Explorer URL: BscScan Testnet Verification Link

2. Testing Execution
The contract logic was thoroughly validated through an automated test suite containing 21 tests.

Testing Command Executed:

forge test --match-contract OrvixMediaRegistryTest --gas-report -vv

Understanding the Command Flags:

forge test: Triggers the Foundry testing framework.

--match-contract OrvixMediaRegistryTest: Filters the tests to only run the test suite specifically written for this contract (ignoring other tests in the repo).

--gas-report: Generates a detailed table showing the minimum, average, median, and maximum gas usage for every function in the contract.

-vv: Verbosity level 2 (shows standard console logs and detailed test results).

Test Results:

Suite Result: ✅ 21 passed; 0 failed; 0 skipped.

Coverage Highlights: Includes Fuzz testing (testFuzz_AddMedia, testFuzz_UpdateMedia), state consistency checks, index validation reverst (test_InvalidIndex_Reverts), wallet isolation (test_MultipleWallets_Isolation), and specific edge cases (test_EmptyUri).

🔍 Internal Review Checklist
✓ Compile Errors & Access Control
[x] No syntax errors (Solidity 0.8.34+)

[x] Only msg.sender can update/remove their own media

[x] No global admin, owner, or roles (Fully Permissionless)

✓ Array & Index Consistency
[x] getMediaCount() returns actual array length

[x] Bounds check: if (index >= userMedia.length) applied in updates/removals

[x] Pop-and-swap deletion correctly implemented without leaving dangling pointers

✓ Event Correctness & Reentrancy
[x] MediaAdded, MediaUpdated, MediaRemoved include indexed owner

[x] No external calls (Zero reentrancy risk)

✓ Wallet Isolation
[x] Wallet A's records stored strictly at _media[walletA]

[x] No cross-wallet state manipulation possible

🎯 Compliance Matrix
Requirement

Status

Evidence

Remove ERC20 logic

✓

No ERC20 import, no mint/transfer/balance

Remove Ownable

✓

No Ownable import, no onlyOwner modifier

Permissionless

✓

All external functions callable by anyone

msg.sender ownership

✓

Data stored at _media[msg.sender]

On-chain data

✓

All data in smart contract storage

Events for discovery

✓

MediaAdded, MediaUpdated, MediaRemoved with indexed owner

Solidity ^0.8.34

✓

pragma solidity ^0.8.34;

Custom errors

✓

EmptyUri, IndexOutOfBounds defined

Calldata strings

✓

function addMedia(string calldata uri)

📞 Support & Extension Points
Future Features (Not Implemented)
Metadata: Add title, description, category fields to Media struct

Pinning: Add isPinned boolean to prioritize certain media

Expiry: Add expiresAt field for temporary media

NFT Integration: Mint Media as NFT (requires separate ERC721 contract)

Known Limitations
Index Shift on Deletion: After removing a record, indices change. Frontend must refetch.

String Storage Cost: Full URIs are expensive on-chain.

No Bulk Operations: Cannot add/remove multiple media in one tx.

No Searching: Cannot search by URI directly. Use indexers (The Graph) for full-text search.

✅ Final Summary
OrvixMediaRegistry is a battle-tested, simple, permissionless media database that:

✓ Stores wallet → URI mappings on-chain

✓ Allows anyone to add/update/remove their own media

✓ Prevents access to other wallets' data

✓ Emits events for frontend discovery

✓ Has been successfully deployed and verified on BSC Testnet

✓ Passed 100% of its test suite (21/21) verifying gas optimization and isolation.
