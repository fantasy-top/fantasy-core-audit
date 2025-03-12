// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RestrictedToken
 * @dev ERC20 token that can only be transferred by the owner or approved senders
 * and allows the owner to burn tokens from any address
 */
contract RestrictedToken is ERC20, Ownable {
    // Mapping of approved senders that can transfer tokens
    mapping(address => bool) public approvedSender;

    constructor() ERC20("Fantasy MON", "fMON") Ownable(msg.sender) {}

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev Approve a sender to transfer tokens
     * @param _sender Address of the sender to approve
     */
    function approveSender(address _sender) external onlyOwner {
        approvedSender[_sender] = true;
    }

    /**
     * @dev Revoke approval for a sender to transfer tokens
     * @param _sender Address of the sender to revoke approval
     */
    function revokeSenderApproval(address _sender) external onlyOwner {
        approvedSender[_sender] = false;
    }

    /**
     * @dev Mint tokens to the caller (only owner)
     * @param amount Amount of tokens to mint
     */
    function getFaucet(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    /**
     * @dev Override transfer to restrict transfers to only the owner or approved senders
     * @param to The recipient address
     * @param value The amount to transfer
     * @return success Whether the transfer was successful
     */
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        if (msg.sender == owner() || approvedSender[msg.sender]) {
            return super.transfer(to, value);
        } else {
            revert("Transfer not allowed: caller is not owner or approved sender");
        }
    }

    /**
     * @dev Override transferFrom to restrict transfers to only the owner or approved senders
     * @param from The sender address
     * @param to The recipient address
     * @param value The amount to transfer
     * @return success Whether the transfer was successful
     */
    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        if (msg.sender == owner() || approvedSender[msg.sender]) {
            return super.transferFrom(from, to, value);
        } else {
            revert("TransferFrom not allowed: caller is not owner or approved sender");
        }
    }

    /**
     * @dev Burns tokens from a specific address (only owner)
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
} 