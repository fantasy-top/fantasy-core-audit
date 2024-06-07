// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

interface IFantasyCardsProxy {
    event ApproveContract(address _contract);
    event DenyContract(address _contract);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event NewExecutionDelegate(address _executionDelegate);
    event NewFantasyCardsCollection(address _fantasyCards);

    // Functions to approve an integration contract to call the functions

    function approveContract(address _contract) external;

    function denyContract(address _contract) external;

    // Functions to interact with the Fantasy Cards contract

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    // Admin functions
    function setExecutionDelegate(address _executionDelegate) external;
    function setFantasyCardsCollection(address _fantasyCards) external;
}
