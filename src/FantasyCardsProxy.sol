pragma solidity ^0.8.20;

import {IFantasyCardsProxy} from "./interfaces/IFantasyCardsProxy.sol";
import "./interfaces/IExecutionDelegate.sol";
import "./interfaces/IFantasyCards.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

contract FantasyCardsProxy is IFantasyCardsProxy, AccessControlDefaultAdminRules, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    mapping(address => bool) public contracts;
    mapping(uint256 tokenId => address) private _tokenApprovals;
    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;
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

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external view returns (uint256) {
        return fantasyCards.balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return fantasyCards.ownerOf(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view returns (string memory) {
        return fantasyCards.name();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return fantasyCards.symbol();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return fantasyCards.tokenURI(tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external override whenNotPaused approvedContract {
        _approve(to, tokenId, tx.origin);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        ownerOf(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfer ERC721 token using `transferFrom`
     * @param from address of the sender
     * @param to address of the recipient, if to is a contract it will not perform any checks
     * @param tokenId tokenId
     */
    function transferFrom(address from, address to, uint256 tokenId) external whenNotPaused approvedContract {
        return executionDelegate.transferERC721Unsafe(address(fantasyCards), from, to, tokenId);
    }

    /**
     * @dev Transfer ERC721 token using `safeTransferFrom`
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override whenNotPaused approvedContract {
        executionDelegate.transferERC721(address(fantasyCards), from, to, tokenId);
    }

    // Can be removed? Cannot be used without modifying execution delegate
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override whenNotPaused approvedContract {}

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        // Avoid reading the owner unless necessary
        if (auth != address(0)) {
            address owner = ownerOf(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert("Invalid operator");
            }

            emit Approval(owner, to, tokenId);
        }

        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        if (operator == address(0)) {
            revert("Invalid operator");
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

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
    function setExecutionDelegate(address _executionDelegate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setExecutionDelegate(_executionDelegate);
    }

    /**
     * @notice Updates the Fantasy Cards contract address.
     * @param _fantasyCards New Fantasy Cards contract address.
     */
    function setFantasyCardsCollection(address _fantasyCards) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
