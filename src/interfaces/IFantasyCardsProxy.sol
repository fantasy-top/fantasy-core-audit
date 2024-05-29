// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

interface IFantasyCardsProxy {
    event ApproveContract(address _contract);
    event DenyContract(address _contract);

    event RevokeApproval(address user);
    event GrantApproval(address user);

    // Functions to approve an integration contract to call the functions

    function approveContract(address _contract) external;

    function denyContract(address _contract) external;

    function revokeApproval() external;

    function grantApproval() external;

    // Functions to interact with the Fantasy Cards contract

    function balanceOf(address owner) external;

    function ownerOf(uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}
