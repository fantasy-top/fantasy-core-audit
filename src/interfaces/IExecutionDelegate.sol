// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IExecutionDelegate {
    event ApproveContract(address indexed _contract);
    event DenyContract(address indexed _contract);

    event RevokeApproval(address indexed user);
    event GrantApproval(address indexed user);

    function approveContract(address _contract) external;

    function denyContract(address _contract) external;

    function revokeApproval() external;

    function grantApproval() external;

    function mintFantasyCard(address collection, address to) external;

    function transferERC721Unsafe(
        address collection,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferERC721(
        address collection,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferERC1155(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    function transferERC20(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}
