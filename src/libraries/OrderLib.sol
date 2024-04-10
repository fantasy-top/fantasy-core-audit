// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library OrderLib {
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address trader,uint8 side,address collection,uint256 tokenId,address paymentToken,uint256 price,uint256 expirationTime,bytes32 merkleRoot,uint256 salt)"
        );

    /// @dev Enum representing the side of the order: Buy or Sell
    enum Side {
        Buy,
        Sell
    }

    /// @dev Structure to represent an order
    /// @param trader Address of the trader placing the order
    /// @param side Side of the order, either Buy or Sell
    /// @param collection Address of the NFT collection
    /// @param tokenId Token ID within the collection (only used for Sell orders)
    /// @param paymentToken Address of the token used for payment
    /// @param price Price of the order
    /// @param expirationTime Expiration time of the order
    /// @param merkleRoot Merkle root of the order (only used for Buy orders)
    /// @param salt A unique value to ensure hash uniqueness
    struct Order {
        address trader;
        Side side;
        address collection;
        uint256 tokenId;
        address paymentToken;
        uint256 price;
        uint256 expirationTime;
        bytes32 merkleRoot;
        uint256 salt;
    }

    /// @dev Internal function to hash an order
    /// @param order The order to hash
    /// @return The hash of the order
    function _hashOrder(Order calldata order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.trader,
                    order.side,
                    order.collection,
                    order.tokenId,
                    order.paymentToken,
                    order.price,
                    order.expirationTime,
                    order.merkleRoot,
                    order.salt
                )
            );
    }
}
