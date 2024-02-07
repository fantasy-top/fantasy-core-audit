/**                                                                                                                                     
    ______            __                  
   / ____/___ _____  / /_____ ________  __
  / /_  / __ `/ __ \/ __/ __ `/ ___/ / / /
 / __/ / /_/ / / / / /_/ /_/ (__  ) /_/ / 
/_/    \__,_/_/ /_/\__/\__,_/____/\__, /  
                                 /____/   

**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/console.sol";

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IBlast.sol";
import "./interfaces/IExecutionDelegate.sol";
import "./interfaces/IExchange.sol";
import "./libraries/OrderLib.sol";

contract Exchange is IExchange, EIP712, Ownable, ReentrancyGuard {
    /* Constants */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    /* Variables */
    mapping(bytes32 orderHash => bool) public cancelledOrFilled;
    mapping(address collection => bool) public whitelistedCollections;
    mapping(address paymentToken => bool) public whitelistedPaymentTokens;
    uint256 public protocolFeeBps;
    address public protocolFeeRecipient;
    IExecutionDelegate public executionDelegate;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Function can only be called by an EOA");
        _;
    }

    /**
     * @notice Contract constructor
     * @param _protocolFeeRecipient Address to receive protocol fees
     * @param _protocolFeeBps Protocol fee basis points
     * @param _executionDelegate Address of the execution delegate contract
     */
    constructor(
        address _protocolFeeRecipient,
        uint256 _protocolFeeBps,
        address _executionDelegate
    ) EIP712("Exchange", "1") Ownable(msg.sender) {
        // REVIEW: When this contract is live
        // IBlast(0x4300000000000000000000000000000000000002)
        //     .configureClaimableGas();
        // IBlast(0x4300000000000000000000000000000000000002).configureGovernor(
        //     msg.sender
        // );
        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeBps = _protocolFeeBps;
        executionDelegate = IExecutionDelegate(_executionDelegate);
    }

    /**
     * @notice Executes a buy operation for a sell order
     * @dev Verifies the validity of the sell order and executes funds and token transfer
     * @param sellOrder The sell order to match with
     * @param sellerSignature Signature of the seller to validate the order
     */
    function buy(
        OrderLib.Order calldata sellOrder,
        bytes calldata sellerSignature
    ) public payable nonReentrant onlyEOA {
        require(sellOrder.side == OrderLib.Side.Sell, "order must be a sell");
        require(sellOrder.expirationTime >= block.timestamp, "order expired");
        require(sellOrder.trader != address(0), "order trader is 0");

        bytes32 sellOrderHash = OrderLib._hashOrder(sellOrder);
        require(
            cancelledOrFilled[sellOrderHash] == false,
            "sell order cancelled or filled"
        );

        bytes32 sellOrderDigest = _hashTypedDataV4(sellOrderHash);
        address sellOrderSigner = ECDSA.recover(
            sellOrderDigest,
            sellerSignature
        );
        require(sellOrderSigner == sellOrder.trader, "invalid signature");

        cancelledOrFilled[sellOrderHash] = true;

        _executeFundsTransfer(
            msg.sender,
            sellOrder.trader,
            sellOrder.paymentToken,
            sellOrder.price
        );

        _executeTokenTransfer(
            sellOrder.collection,
            sellOrder.trader,
            msg.sender,
            sellOrder.tokenId
        );

        emit Buy(msg.sender, sellOrder, sellOrderHash);
    }

    /**
     * @notice Allows a seller to execute a sell operation for a buy order
     * @dev Verifies the validity of the buy order and executes funds and token transfer
     * @param buyOrder The buy order to match with
     * @param buyerSignature Signature of the buyer to validate the order
     * @param tokenId The ID of the token being sold
     * @param merkleProof The merkle proof verifying the tokenId belongs to the merkle root in the buy order
     */
    function sell(
        OrderLib.Order calldata buyOrder,
        bytes calldata buyerSignature,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) public payable nonReentrant onlyEOA {
        require(
            buyOrder.paymentToken != address(0),
            "payment token can not be ETH for buy order"
        );
        require(buyOrder.side == OrderLib.Side.Buy, "order must be a buy");
        require(buyOrder.expirationTime >= block.timestamp, "order expired");
        require(buyOrder.trader != address(0), "order trader is 0");

        bytes32 buyOrderHash = OrderLib._hashOrder(buyOrder);
        require(
            cancelledOrFilled[buyOrderHash] == false,
            "buy order cancelled or filled"
        );

        bytes32 buyOrderDigest = _hashTypedDataV4(buyOrderHash);
        address buyOrderSigner = ECDSA.recover(buyOrderDigest, buyerSignature);
        require(buyOrderSigner == buyOrder.trader, "invalid signature");

        require(
            _verifyTokenId(buyOrder.merkleRoot, merkleProof, tokenId),
            "invalid tokenId"
        );

        cancelledOrFilled[buyOrderHash] = true;

        _executeFundsTransfer(
            buyOrder.trader,
            msg.sender,
            buyOrder.paymentToken,
            buyOrder.price
        );

        _executeTokenTransfer(
            buyOrder.collection,
            msg.sender,
            buyOrder.trader,
            tokenId
        );

        emit Sell(
            msg.sender, // Seller's address
            buyOrder, // The buy order details
            tokenId, // The ID of the token being sold
            buyOrderHash // The hash of the buy order
        );
    }

    /**
     * @notice Cancels an order, preventing it from being executed
     * @dev Sets the order's hash in the `cancelledOrFilled` mapping to true
     * @param order The order to cancel
     */
    function cancelOrder(OrderLib.Order calldata order) public {
        require(order.trader == msg.sender, "msg.sender is not the trader");

        bytes32 orderHash = OrderLib._hashOrder(order);
        cancelledOrFilled[orderHash] = true;
    }

    /**
     * @notice Whitelists a payment token, allowing it to be used in transactions
     * @dev Only callable by the contract owner. This function adds a payment token to the list of tokens
     * that can be used for buying and selling on the exchange. Emits a `NewWhitelistedPaymentToken` event on success.
     * @param _paymentToken The address of the ERC-20 payment token to whitelist
     */
    function whiteListPaymentToken(address _paymentToken) public onlyOwner {
        whitelistedPaymentTokens[_paymentToken] = true;

        emit NewWhitelistedPaymentToken(_paymentToken);
    }

    /**
     * @notice Removes a payment token from the whitelist, preventing it from being used in future transactions
     * @dev Only callable by the contract owner. This function removes a payment token from the list of tokens
     * that are allowed for transactions. Emits an `UnWhitelistedPaymentToken` event on success.
     * @param _paymentToken The address of the ERC-20 payment token to remove from the whitelist
     */
    function unWhiteListPaymentToken(address _paymentToken) public onlyOwner {
        whitelistedPaymentTokens[_paymentToken] = false;

        emit UnWhitelistedPaymentToken(_paymentToken);
    }

    /**
     * @notice Whitelists a collection, allowing its tokens to be traded on the exchange
     * @dev Only callable by the contract owner. This function adds a collection to the list of NFT collections
     * that can be bought and sold on the exchange. Emits a `NewWhitelistedCollection` event on success.
     * @param _collection The address of the ERC-721 token collection to whitelist
     */
    function whiteListCollection(address _collection) public onlyOwner {
        whitelistedCollections[_collection] = true;

        emit NewWhitelistedCollection(_collection);
    }

    /**
     * @notice Removes a collection from the whitelist, preventing its tokens from being traded on the exchange
     * @dev Only callable by the contract owner. This function removes a collection from the list of collections
     * that are allowed to be traded. Emits an `UnWhitelistedCollection` event on success.
     * @param _collection The address of the ERC-721 token collection to remove from the whitelist
     */
    function unWhiteListCollection(address _collection) public onlyOwner {
        whitelistedCollections[_collection] = false;

        emit UnWhitelistedCollection(_collection);
    }

    /**
     * @notice Sets a new protocol fee in basis points
     * @param _protocolFeeBps The new protocol fee in basis points
     */
    function setProtocolFeeBps(uint256 _protocolFeeBps) public onlyOwner {
        protocolFeeBps = _protocolFeeBps;

        emit NewProtocolFeeBps(_protocolFeeBps);
    }

    /**
     * @notice Sets a new protocol fee recipient address
     * @param _protocolFeeRecipient The address of the new protocol fee recipient
     */
    function setProtocolFeeRecipient(
        address _protocolFeeRecipient
    ) public onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;

        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @notice Sets a new execution delegate address
     * @param _executionDelegate The address of the new execution delegate
     */
    function setExecutionDelegate(address _executionDelegate) public onlyOwner {
        executionDelegate = IExecutionDelegate(_executionDelegate);

        emit NewExecutionDelegate(_executionDelegate);
    }

    /**
     * @notice Function to get the Domain Separator
     * @return bytes32: EIP712 Domain Separator
     */
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev Execute all ERC20 token / ETH transfers associated with an order match (fees and buyer => seller transfer)
     * @param from from
     * @param to to
     * @param paymentToken payment token
     * @param price price
     */
    function _executeFundsTransfer(
        address from,
        address to,
        address paymentToken,
        uint256 price
    ) internal {
        if (paymentToken == address(0)) {
            require(msg.value == price, "Incorrect ETH amount");
        }

        /* Take fee. */
        uint256 receiveAmount = _transferFees(paymentToken, from, price);

        /* Transfer remainder to seller. */
        _transferTo(paymentToken, from, to, receiveAmount);
    }

    /**
     * @dev Charge a fee in ETH or WETH
     * @param paymentToken address of token to pay in
     * @param from address to charge fees
     * @param price price of token
     */
    function _transferFees(
        address paymentToken,
        address from,
        uint256 price
    ) internal returns (uint256) {
        uint256 protocolFee = (price * protocolFeeBps) / INVERSE_BASIS_POINT;
        _transferTo(paymentToken, from, protocolFeeRecipient, protocolFee);

        require(
            protocolFee <= price,
            "Total amount of fees are more than the price"
        );

        /* Amount that will be received by seller. */
        uint256 receiveAmount = price - protocolFee;
        return (receiveAmount);
    }

    /**
     * @dev Transfer amount in ETH or ERC20
     * @param paymentToken address of token to pay in
     * @param from token sender
     * @param to token recipient
     * @param amount amount to transfer
     */
    function _transferTo(
        address paymentToken,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (paymentToken == address(0)) {
            /* Transfer funds in ETH. */
            payable(to).transfer(amount);
        } else if (whitelistedPaymentTokens[paymentToken]) {
            /* Transfer ERC20. */
            executionDelegate.transferERC20(paymentToken, from, to, amount);
        } else {
            revert("Invalid payment token");
        }
    }

    /**
     * @dev Execute call through delegate proxy
     * @param collection collection contract address
     * @param from from
     * @param to to
     * @param tokenId tokenId
     */
    function _executeTokenTransfer(
        address collection,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        /* Assert collection is whitelisted */
        require(
            whitelistedCollections[collection],
            "Collection is not withelisted"
        );

        /* Call execution delegate. */
        executionDelegate.transferERC721(collection, from, to, tokenId);
    }

    /**
     * @dev Verifies the validity of a token ID against a given Merkle root using a Merkle proof.
     * @param merkleRoot The root of the Merkle tree.
     * @param merkleProof An array of bytes32 values that represent the Merkle proof.
     * @param tokenId The token ID to verify.
     * @return bool Returns true if the token ID is valid and belongs to the Merkle tree defined by the root, otherwise false.
     */
    function _verifyTokenId(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 tokenId
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(tokenId));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }
}
