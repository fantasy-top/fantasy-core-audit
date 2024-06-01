pragma solidity ^0.8.20;

import {IFantasyCardsProxy} from "./interfaces/IFantasyCardsProxy.sol";
import "./interfaces/IExecutionDelegate.sol";
import "./interfaces/IFantasyCards.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

contract FantasyCardsProxy is IFantasyCardsProxy, AccessControlDefaultAdminRules, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    mapping(uint256 tokenId => address) private _tokenApprovals;
    mapping(address => bool) public contracts;
    mapping(address => bool) public revokedApproval;
    IExecutionDelegate public executionDelegate;
    IFantasyCards public fantasyCards;

    modifier approvedContract() {
        require(contracts[msg.sender], "Contract is not approved to make transfers");
        _;
    }

    constructor(address _executionDelegate, address _fantasyCards) AccessControlDefaultAdminRules(0, msg.sender) {
        _setExecutionDelegate(_executionDelegate);
        _setFantasyCardsCollection(_fantasyCards);
    }

    /* 
    ======================
        FANTASY CARDS PROXY FUNCTIONS
    ======================
    */

    function approve(address to, uint256 tokenId) external override whenNotPaused approvedContract {}

    function setApprovalForAll(address operator, bool approved) external override whenNotPaused approvedContract {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override whenNotPaused approvedContract {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override whenNotPaused approvedContract {}

    function transferFrom(address from, address to, uint256 tokenId) external override whenNotPaused approvedContract {}

    // View functions

    function balanceOf(address owner) external view override returns (uint256) {
        return fantasyCards.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        return fantasyCards.ownerOf(tokenId);
    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return fantasyCards.isApprovedForAll(owner, operator);
    }

    /* 
    ======================
        ADMIN FUNCTIONS
    ======================
    */

    /**
     * @dev Approve contract to use proxy functions
     * @param _contract address of contract to approve
     */
    function approveContract(address _contract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contracts[_contract] = true;
        emit ApproveContract(_contract);
    }

    /**
     * @dev Revoke approval of contract to use proxy functions
     * @param _contract address of contract to revoke approval
     */
    function denyContract(address _contract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contracts[_contract] = false;
        emit DenyContract(_contract);
    }

    /**
     * @notice Updates the execution delegate address.
     * @param _executionDelegate New delegate address.
     */
    function setExecutionDelegate(address _executionDelegate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setExecutionDelegate(_executionDelegate);
    }

    /**
     * @notice Updates the Fantasy Cards contract address.
     * @param _fantasyCards New Fantasy Cards contract address.
     */
    function setFantasyCardsCollection(address _fantasyCards) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setFantasyCardsCollection(_fantasyCards);
    }

    /**
     * @notice Internal function that updates the Fantasy Cards contract address.
     * @param _fantasyCards New Fantasy Cards contract address.
     */
    function _setFantasyCardsCollection(address _fantasyCards) internal {
        require(_fantasyCards != address(0), "Fantasy Cards address cannot be 0x0");
        fantasyCards = IFantasyCards(_fantasyCards);

        emit NewFantasyCardsCollection(_fantasyCards);
    }

    /**
     * @notice Internal function that updates the execution delegate address.
     * @param _executionDelegate New delegate address.
     */
    function _setExecutionDelegate(address _executionDelegate) internal {
        require(_executionDelegate != address(0), "Execution delegate address cannot be 0x0");
        executionDelegate = IExecutionDelegate(_executionDelegate);

        emit NewExecutionDelegate(_executionDelegate);
    }

    /**
     * @dev Pause contract
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
