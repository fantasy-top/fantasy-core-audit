pragma solidity ^0.8.20;

import {IFantasyCardsProxy} from "./interfaces/IFantasyCardsProxy.sol";
import "./interfaces/IExecutionDelegate.sol";
import "./interfaces/IFantasyCards.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract FantasyCardsProxy is IFantasyCardsProxy, AccessControlDefaultAdminRules, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    mapping(address => bool) public integrators;
    mapping(uint256 tokenId => address) private _tokenApprovals;
    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;
    IExecutionDelegate public executionDelegate;
    IFantasyCards public fantasyCards;

    modifier approvedIntegrator() {
        require(integrators[msg.sender], "Integrator is not approved");
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
    function approve(address to, uint256 tokenId) external override whenNotPaused {
        _approve(to, tokenId, msg.sender, true);
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
    function setApprovalForAll(address operator, bool approved) external override whenNotPaused {
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
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused approvedIntegrator {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _updateApproval(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
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
    ) external override whenNotPaused approvedIntegrator {
       safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * with additional data if the recipient is a contract.
     * Usage of this method is restricted to contracts or approved operators.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external override whenNotPaused approvedIntegrator {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Removes the approval at the proxy level of the `tokenId` from the owner.
     * Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     */
    function _updateApproval(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);
        }

        emit Transfer(from, to, tokenId);

        return from;
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
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = ownerOf(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
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
            revert ERC721InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    // Admin functions of the contract

    /**
     * @dev Approve integrator to use proxy functions
     * @param _integrator address of contract to approve
     */
    function approveIntegrator(address _integrator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        integrators[_integrator] = true;
        emit ApproveIntegrator(_integrator);
    }

    /**
     * @dev Revoke approval of integrator to use proxy functions
     * @param _integrator address of integrator to revoke approval
     */
    function denyIntegrator(address _integrator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        integrators[_integrator] = false;
        emit DenyIntegrator(_integrator);
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
