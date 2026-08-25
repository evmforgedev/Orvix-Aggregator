// SPDX-License-Identifier: MIT

pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {OrvixMediaRegistry} from "../src/OrvixMediaRegistry.sol";

/**
 * @title OrvixMediaRegistry Test Contract
 * @author Orvix Team
 * @notice Comprehensive test suite for OrvixMediaRegistry contract
 * @dev Uses Foundry's standard testing framework with fuzzing and gas reporting
 */
contract OrvixMediaRegistryTest is Test {
    OrvixMediaRegistry public registry;

    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    // Events for checking
    event MediaAdded(address indexed owner, uint256 indexed index, string uri, uint256 timestamp);
    event MediaUpdated(address indexed owner, uint256 indexed index, string uri, uint256 timestamp);
    event MediaRemoved(address indexed owner, uint256 indexed index, string uri);

    /**
     * @notice Sets up the test environment before each test case
     * @dev Deploys a new registry contract and labels addresses for better traceability
     */
    function setUp() public {
        registry = new OrvixMediaRegistry();
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(registry), "Registry");
    }

    /**
     * @notice Tests that the contract was properly deployed
     * @dev Verifies that the registry address is not zero
     */
    function test_Deployment() public view {
        assertTrue(address(registry) != address(0), "Contract not deployed");
    }

    /**
     * @notice Tests adding multiple media items with different URI formats
     * @dev Verifies correct storage, indexing, and timestamp recording
     *      Tests various URI formats: HTTP, HTTPS, IPFS, TikTok links
     */
    function test_AddMedia() public {
        vm.startPrank(alice);

        string[5] memory uris = [
            "https://example.com/image.jpg",
            "https://example.com/video.mp4",
            "https://example.com/page",
            "ipfs://QmExample",
            "https://www.tiktok.com/@example/video/123"
        ];

        uint256 expectedTime = 1700000000;
        vm.warp(expectedTime);

        for (uint256 i = 0; i < uris.length; i++) {
            // Expect Event MediaAdded
            vm.expectEmit(true, true, false, true);
            emit MediaAdded(alice, i, uris[i], expectedTime);

            registry.addMedia(uris[i]);

            // Check State
            assertEq(registry.getMediaCount(alice), i + 1, "Count should increment");

            (string memory uri, uint256 createdAt) = registry.getMediaAt(alice, i);
            assertEq(uri, uris[i], "URI mismatch");
            assertEq(createdAt, expectedTime, "Timestamp mismatch");
        }

        vm.stopPrank();
    }

    /**
     * @notice Tests that media items are stored and retrieved in correct order
     * @dev Verifies the array index ordering for multiple additions
     */
    function test_MultipleMedia() public {
        vm.startPrank(alice);

        registry.addMedia("URI_1");
        registry.addMedia("URI_2");
        registry.addMedia("URI_3");

        assertEq(registry.getMediaCount(alice), 3);

        (string memory uri0, ) = registry.getMediaAt(alice, 0);
        (string memory uri1, ) = registry.getMediaAt(alice, 1);
        (string memory uri2, ) = registry.getMediaAt(alice, 2);

        assertEq(uri0, "URI_1");
        assertEq(uri1, "URI_2");
        assertEq(uri2, "URI_3");

        OrvixMediaRegistry.Media[] memory allMedia = registry.getMedia(alice);
        assertEq(allMedia.length, 3);
        assertEq(allMedia[0].uri, "URI_1");
        assertEq(allMedia[2].uri, "URI_3");

        vm.stopPrank();
    }

    /**
     * @notice Tests ownership isolation between different wallets
     * @dev Verifies that users can only access and modify their own media
     *      Security test: Bob cannot access or modify Alice's media
     */
    function test_MultipleWallets_Isolation() public {
        // Alice adds her media
        vm.prank(alice);
        registry.addMedia("Alice_URI_0");

        // Bob adds his media
        vm.startPrank(bob);
        registry.addMedia("Bob_URI_0");
        registry.addMedia("Bob_URI_1");

        // Isolation Check: Bob tries to update Alice's media by guessing index 0.
        // But the contract maps msg.sender, so Bob only updates HIS OWN index 0.
        registry.updateMedia(0, "Bob_Hacked_URI");

        // Assert Bob changed his own media
        (string memory bobUri, ) = registry.getMediaAt(bob, 0);
        assertEq(bobUri, "Bob_Hacked_URI");

        // Bob tries to access index 2 (doesn't exist in his array)
        vm.expectRevert(abi.encodeWithSelector(OrvixMediaRegistry.IndexOutOfBounds.selector, 2, 1));
        registry.removeMedia(2);

        vm.stopPrank();

        // Ensure Alice's data remains untouched
        (string memory aliceUri, ) = registry.getMediaAt(alice, 0);
        assertEq(aliceUri, "Alice_URI_0");
        assertEq(registry.getMediaCount(alice), 1);
        assertEq(registry.getMediaCount(bob), 2);
    }

    /**
     * @notice Tests getMedia and getMediaCount functions
     * @dev Verifies correct length reporting and media retrieval
     *      Tests both empty and populated states
     */
    function test_GetMedia_And_Count() public {
        // Empty array
        assertEq(registry.getMedia(alice).length, 0);
        assertEq(registry.getMediaCount(alice), 0);

        vm.startPrank(alice);

        // Add 1
        registry.addMedia("URI_1");
        assertEq(registry.getMedia(alice).length, 1);
        assertEq(registry.getMediaCount(alice), 1);

        // Add 2
        registry.addMedia("URI_2");
        assertEq(registry.getMediaCount(alice), 2);

        // Remove 1
        registry.removeMedia(0);
        assertEq(registry.getMediaCount(alice), 1);

        vm.stopPrank();
    }

    /**
     * @notice Tests revert conditions for invalid index operations
     * @dev Verifies IndexOutOfBounds error is thrown for out-of-range indices
     *      Tests empty array, out of bounds, and negative-like indices
     */
    function test_InvalidIndex_Reverts() public {
        // On empty array
        vm.startPrank(alice);

        vm.expectRevert(abi.encodeWithSelector(OrvixMediaRegistry.IndexOutOfBounds.selector, 0, 0));
        registry.getMediaAt(alice, 0);

        vm.expectRevert(abi.encodeWithSelector(OrvixMediaRegistry.IndexOutOfBounds.selector, 0, 0));
        registry.updateMedia(0, "NEW_URI");

        vm.expectRevert(abi.encodeWithSelector(OrvixMediaRegistry.IndexOutOfBounds.selector, 0, 0));
        registry.removeMedia(0);

        // On array with 1 item
        registry.addMedia("URI_1");

        vm.expectRevert(abi.encodeWithSelector(OrvixMediaRegistry.IndexOutOfBounds.selector, 1, 0));
        registry.getMediaAt(alice, 1);

        vm.expectRevert(abi.encodeWithSelector(OrvixMediaRegistry.IndexOutOfBounds.selector, 5, 0));
        registry.removeMedia(5);

        vm.stopPrank();
    }

    /**
     * @notice Tests that empty URIs are rejected
     * @dev Verifies EmptyUri error is thrown when empty string is provided
     *      Security test to prevent empty data entries
     */
    function test_EmptyUri() public {
        vm.startPrank(alice);

        vm.expectRevert(OrvixMediaRegistry.EmptyUri.selector);
        registry.addMedia("");

        registry.addMedia("VALID_URI");

        vm.expectRevert(OrvixMediaRegistry.EmptyUri.selector);
        registry.updateMedia(0, "");

        vm.stopPrank();
    }

    /**
     * @notice Tests updating existing media URIs
     * @dev Verifies that URI updates correctly and timestamp remains unchanged
     *      Creation timestamp should persist through updates
     */
    function test_UpdateMedia() public {
        vm.startPrank(alice);

        uint256 creationTime = 1000;
        vm.warp(creationTime);
        registry.addMedia("OLD_URI");

        uint256 updateTime = 2000;
        vm.warp(updateTime);

        vm.expectEmit(true, true, false, true);
        emit MediaUpdated(alice, 0, "NEW_URI", updateTime);

        registry.updateMedia(0, "NEW_URI");

        (string memory uri, uint256 createdAt) = registry.getMediaAt(alice, 0);
        assertEq(uri, "NEW_URI", "URI should change");
        assertEq(createdAt, creationTime, "Created Timestamp should NOT change");

        vm.stopPrank();
    }

    /**
     * @notice Tests removing a single media item
     * @dev Verifies successful removal and count decrement
     */
    function test_RemoveMedia_Single() public {
        vm.prank(alice);
        registry.addMedia("URI_A");

        vm.prank(alice);
        registry.removeMedia(0);

        assertEq(registry.getMediaCount(alice), 0);
    }

    /**
     * @notice Tests the swap-and-pop removal mechanism
     * @dev Verifies that removal maintains array continuity
     *      Tests removing from middle, end, and beginning of array
     */
    function test_RemoveMedia_SwapAndPop() public {
        vm.startPrank(alice);

        registry.addMedia("URI_A"); // index 0
        registry.addMedia("URI_B"); // index 1
        registry.addMedia("URI_C"); // index 2
        registry.addMedia("URI_D"); // index 3

        // Test Remove Middle (index 1 / URI_B)
        vm.expectEmit(true, true, false, true);
        emit MediaRemoved(alice, 1, "URI_B");
        registry.removeMedia(1);

        assertEq(registry.getMediaCount(alice), 3);

        // Check Swap (URI_D should move to index 1)
        (string memory uri0, ) = registry.getMediaAt(alice, 0);
        (string memory uri1, ) = registry.getMediaAt(alice, 1);
        (string memory uri2, ) = registry.getMediaAt(alice, 2);

        assertEq(uri0, "URI_A");
        assertEq(uri1, "URI_D"); // Swapped from the last position
        assertEq(uri2, "URI_C");

        // Test Remove Last (index 2 / URI_C)
        registry.removeMedia(2);
        assertEq(registry.getMediaCount(alice), 2);

        (string memory finalUri1, ) = registry.getMediaAt(alice, 1);
        assertEq(finalUri1, "URI_D"); // No swap needed, just popped

        // Test Remove First (index 0 / URI_A)
        registry.removeMedia(0);
        assertEq(registry.getMediaCount(alice), 1);

        (string memory lastStandingUri, ) = registry.getMediaAt(alice, 0);
        assertEq(lastStandingUri, "URI_D"); // URI_D swapped to index 0

        vm.stopPrank();
    }

    /**
     * @notice Tests state consistency across multiple operations
     * @dev Verifies that invariant (count == array length) holds
     *      Executes a sequence of add, update, and remove operations
     */
    function test_Sequence_StateConsistency() public {
        vm.startPrank(alice);

        registry.addMedia("1");
        registry.addMedia("2");
        registry.updateMedia(0, "1_Updated");
        registry.removeMedia(1);
        registry.addMedia("3");

        OrvixMediaRegistry.Media[] memory aliceMedia = registry.getMedia(alice);

        // Length should be 2 ("1_Updated" and "3")
        assertEq(aliceMedia.length, 2, "Length mismatch");
        assertEq(registry.getMediaCount(alice), aliceMedia.length, "Invariant broken");
        assertEq(aliceMedia[0].uri, "1_Updated");
        assertEq(aliceMedia[1].uri, "3");

        vm.stopPrank();
    }

    /**
     * @notice Fuzz test for adding media with random URIs and timestamps
     * @dev Tests contract behavior with various valid URI formats
     *      Assumes URI length > 0 to avoid empty string reverts
     * @param uri Random string to use as URI
     * @param timestamp Random timestamp to warp time to
     */
    function testFuzz_AddMedia(string calldata uri, uint256 timestamp) public {
        vm.assume(bytes(uri).length > 0); // Ignore empty strings

        vm.warp(timestamp);
        vm.prank(alice);
        registry.addMedia(uri);

        (string memory savedUri, uint256 savedTime) = registry.getMediaAt(alice, 0);
        assertEq(savedUri, uri);
        assertEq(savedTime, timestamp);
    }

    /**
     * @notice Fuzz test for updating media URIs
     * @dev Tests that URIs can be updated to any non-empty string
     * @param uri1 Initial URI
     * @param uri2 Updated URI
     */
    function testFuzz_UpdateMedia(string calldata uri1, string calldata uri2) public {
        vm.assume(bytes(uri1).length > 0 && bytes(uri2).length > 0);

        vm.startPrank(alice);
        registry.addMedia(uri1);
        registry.updateMedia(0, uri2);

        (string memory finalUri, ) = registry.getMediaAt(alice, 0);
        assertEq(finalUri, uri2);

        vm.stopPrank();
    }

    /**
     * @notice Gas test for adding short URI
     * @dev Measures gas cost for adding a short string
     */
    function testGas_AddShortURI() public {
        vm.prank(alice);
        registry.addMedia("pic.png");
    }

    /**
     * @notice Gas test for adding medium URI
     * @dev Measures gas cost for adding a standard URL
     */
    function testGas_AddMediumURI() public {
        vm.prank(alice);
        registry.addMedia("https://example.com/image.jpg");
    }

    /**
     * @notice Gas test for adding long URI
     * @dev Measures gas cost for adding a very long URL with parameters
     */
    function testGas_AddLongURI() public {
        vm.prank(alice);
        registry.addMedia("https://superlongdomainnameexamplethatkeepson.going/somereallylongpath/withalotofparameters?id=1234567890&token=abcdefghijklmnopqrstuvwxyz");
    }

    /**
     * @notice Gas test for adding IPFS URI
     * @dev Measures gas cost for adding IPFS protocol URI
     */
    function testGas_AddIpfsURI() public {
        vm.prank(alice);
        registry.addMedia("ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG");
    }

    /**
     * @notice Gas test for adding HTTPS URI
     * @dev Measures gas cost for adding HTTPS protocol URI
     */
    function testGas_AddHttpsURI() public {
        vm.prank(alice);
        registry.addMedia("https://www.tiktok.com/@example/video/123");
    }

    /**
     * @notice Gas test for updating media
     * @dev Measures gas cost of updating existing media URI
     */
    function testGas_UpdateMedia() public {
        vm.startPrank(alice);
        registry.addMedia("OLD_URI");
        registry.updateMedia(0, "NEW_URI_LONGER");
        vm.stopPrank();
    }

    /**
     * @notice Gas test for removing media
     * @dev Measures gas cost of removing media with swap-and-pop
     */
    function testGas_RemoveMedia() public {
        vm.startPrank(alice);
        registry.addMedia("URI_A");
        registry.addMedia("URI_B");
        registry.removeMedia(0); // Measure worst-case swap-and-pop
        vm.stopPrank();
    }

    /**
     * @notice Gas test for getter functions
     * @dev Measures combined gas cost of all view functions
     */
    function testGas_Getters() public {
        vm.startPrank(alice);
        registry.addMedia("URI_A");
        registry.getMediaCount(alice);
        registry.getMediaAt(alice, 0);
        registry.getMedia(alice);
        vm.stopPrank();
    }
}
