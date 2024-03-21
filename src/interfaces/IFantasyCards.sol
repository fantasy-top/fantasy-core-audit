// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

interface IFantasyCards is IERC721, IERC721Metadata, IERC721Errors {
    function safeMint(address to) external;

    function setBaseURI(string calldata _baseURI) external;

    function burn(uint256 tokenId) external;

    function tokenCounter() external view returns (uint256);
}
