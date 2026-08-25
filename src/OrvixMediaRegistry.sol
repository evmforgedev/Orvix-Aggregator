// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

/**

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
           ▐▓▓▓▓▓▓▓▄                         ┌▄▄▄▄  ╖╖╖╖,       ╓,╓╓÷
            ▀▓▓▓▓▓▓▓▄                        ▐████   %▒▒▒@    .▒░▒▒∩
             ▀███████▄                     ,▓▐████    └╬▒▒▒U ╓░▒▒╝
              ▀████████▄                 ,▄██▐████      ╙▒░░▒▒▒▒∩
               ▀█████████▓ ▄,         ,▄▓████▐████       `▒▒▒▒▒
                  ▀████████████▓▓▓▓▓█████████▐████      ╓▒▒▒▒▒▒▓µ
                    ╙▀███████████████████████▐████    ,▒▒▒▒∩ ╚▒▓▓▓
                        "▀▀██████████████▀▀╙ ▐████   ╗▒▒▒╝    `▓▓▓▓φ
                           ``" ▀▀▀▀▀╙"`      └▀▀▀▀  """╙`       "╙"""

                        ███████ ORVIX Labs ███████

*/
/**
 * @title OrvixMediaRegistry
 * @dev A permissionless on-chain media database.
 * 
 * Stores wallet address → URI mappings for images, videos, links, IPFS, etc.
 * Anyone can store media. msg.sender automatically owns their records.
 * Frontend fetches URIs and renders them (image/video/link).
 * 
 * Designed for wallet, dApp, and infrastructure integrations.
 * Copyright (c) 2026 ORVIX Labs
 * Licensed under MIT.
 * https://github.com/evmforgedev
 */

contract OrvixMediaRegistry {
    
    // ============ STRUCTS ============
    
    /// @dev Media record: URI + creation timestamp
    struct Media {
        string uri;
        uint256 createdAt;
    }
    
    // ============ STATE VARIABLES ============
    
    /// @dev Wallet address → array of Media records
    mapping(address => Media[]) private _media;
    
    // ============ EVENTS ============
    
    /// @dev Emitted when a new media is added
    event MediaAdded(
        address indexed owner,
        uint256 indexed index,
        string uri,
        uint256 timestamp
    );
    
    /// @dev Emitted when media is updated
    event MediaUpdated(
        address indexed owner,
        uint256 indexed index,
        string uri,
        uint256 timestamp
    );
    
    /// @dev Emitted when media is removed
    event MediaRemoved(
        address indexed owner,
        uint256 indexed index,
        string uri
    );
    
    // ============ CUSTOM ERRORS ============
    
    /// @dev Thrown when provided URI is empty
    error EmptyUri();
    
    /// @dev Thrown when index is out of bounds for user's media array
    error IndexOutOfBounds(uint256 index, uint256 maxIndex);
    
    // ============ CORE FUNCTIONS ============
    
    /**
     * @notice Adds a new media record for msg.sender.
     * @dev Permissionless. Any wallet can call this to store their own media.
     * @param uri The media URI (HTTPS, IPFS, image, video, link, etc.)
     * 
     * Emits: MediaAdded
     * Requirements:
     *  - uri must not be empty
     */
    function addMedia(string calldata uri) external {
        if (bytes(uri).length == 0) revert EmptyUri();
        
        _media[msg.sender].push(
            Media({
                uri: uri,
                createdAt: block.timestamp
            })
        );
        
        uint256 index = _media[msg.sender].length - 1;
        emit MediaAdded(msg.sender, index, uri, block.timestamp);
    }
    
    /**
     * @notice Returns all media records for a user.
     * @param user The wallet address to query.
     * @return Array of Media struct (uri, createdAt).
     * 
     * Returns empty array if user has no media.
     */
    function getMedia(address user)
        external
        view
        returns (Media[] memory)
    {
        return _media[user];
    }
    
    /**
     * @notice Returns the total count of media records for a user.
     * @param user The wallet address to query.
     * @return Total number of media records.
     */
    function getMediaCount(address user)
        external
        view
        returns (uint256)
    {
        return _media[user].length;
    }
    
    /**
     * @notice Returns a single media record at a specific index.
     * @param user The wallet address to query.
     * @param index The index of the media record (0-based).
     * @return uri The media URI string.
     * @return createdAt The Unix timestamp when media was added.
     * 
     * Reverts: IndexOutOfBounds
     */
    function getMediaAt(address user, uint256 index)
        external
        view
        returns (string memory uri, uint256 createdAt)
    {
        Media[] storage userMedia = _media[user];
        if (index >= userMedia.length) {
            revert IndexOutOfBounds(index, userMedia.length > 0 ? userMedia.length - 1 : 0);
        }
        
        Media storage media = userMedia[index];
        return (media.uri, media.createdAt);
    }
    
    /**
     * @notice Updates an existing media record.
     * @dev Only msg.sender can update their own media.
     * @param index The index of the media to update.
     * @param newUri The new media URI.
     * 
     * Emits: MediaUpdated
     * Reverts:
     *  - EmptyUri (if newUri is empty)
     *  - IndexOutOfBounds (if index is invalid)
     */
    function updateMedia(uint256 index, string calldata newUri)
        external
    {
        if (bytes(newUri).length == 0) revert EmptyUri();
        
        Media[] storage userMedia = _media[msg.sender];
        if (index >= userMedia.length) {
            revert IndexOutOfBounds(index, userMedia.length > 0 ? userMedia.length - 1 : 0);
        }
        
        userMedia[index].uri = newUri;
        
        emit MediaUpdated(msg.sender, index, newUri, block.timestamp);
    }
    
    /**
     * @notice Removes a media record from msg.sender's collection.
     * @dev Only msg.sender can remove their own media.
     * 
     * IMPLEMENTATION NOTE: Uses pop-and-swap deletion pattern for gas efficiency.
     * This means after removal, the last element shifts to fill the deleted position,
     * and all indices after the removed index will shift down by 1.
     * 
     * Frontend implications:
     *  - After calling removeMedia, refetch getMedia() to get updated indices
     *  - If storing index in frontend state, validate it after removal
     *  - Use URI as primary identifier, not index, for user-facing features
     * 
     * @param index The index of the media to remove.
     * 
     * Emits: MediaRemoved
     * Reverts: IndexOutOfBounds (if index is invalid)
     */
    function removeMedia(uint256 index) external {
        Media[] storage userMedia = _media[msg.sender];
        
        if (index >= userMedia.length) {
            revert IndexOutOfBounds(index, userMedia.length > 0 ? userMedia.length - 1 : 0);
        }
        
        // Capture URI before array modification
        string memory removedUri = userMedia[index].uri;
        
        // Swap with last element (if not already last) and pop
        if (index != userMedia.length - 1) {
            userMedia[index] = userMedia[userMedia.length - 1];
        }
        userMedia.pop();
        
        emit MediaRemoved(msg.sender, index, removedUri);
    }
}

