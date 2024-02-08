// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMinter {
    // Events
    event NewMintConfig(
        uint256 mintConfigId,
        address collection,
        uint256 cardsPerPack,
        uint256 maxPacks,
        address paymentToken,
        uint256 price,
        bool onePerAddress,
        bool requiresWhitelist,
        bytes32 merkleRoot,
        uint256 expirationTimestamp
    );
    event Mint(uint256 mintConfigId, address buyer, uint256 totalMintedPacks);
    event NewTreasury(address treasury);
    event CollectionUpdatedForMintConfig(
        uint256 mintConfigId,
        address newCollection
    );
    event CardsPerPackUpdatedForMintConfig(
        uint256 mintConfigId,
        uint256 newCardsPerPack
    );
    event MaxPacksUpdatedForMintConfig(
        uint256 mintConfigId,
        uint256 newMaxPacks
    );
    event PaymentTokenUpdatedForMintConfig(
        uint256 mintConfigId,
        address newPaymentToken
    );
    event PriceUpdatedForMintConfig(
        uint256 mintConfigId,
        uint256 newPrice
    );
    event OnePerAddressUpdatedForMintConfig(
        uint256 mintConfigId,
        bool newOnePerAddress
    );
    event WhitelistRequirementUpdatedForMintConfig(
        uint256 mintConfigId,
        bool newRequiresWhitelist
    );
    event MerkleRootUpdatedForMintConfig(
        uint256 mintConfigId,
        bytes32 newMerkleRoot
    );
    event MintConfigCancelled(uint256 mintConfigId);
    event ExpirationTimestampUpdatedForMintConfig(
        uint256 mintConfigId,
        uint256 newExpirationTimestamp
    );

    // Functions
    function mint(
        uint256 configId,
        bytes32[] calldata merkleProof
    ) external payable;

    function newMintConfig(
        address collection,
        uint256 cardsPerPack,
        uint256 maxPacks,
        address paymentToken,
        uint256 price,
        bool onePerAddress,
        bool requiresWhitelist,
        bytes32 merkleRoot,
        uint256 expirationTimestamp
    ) external;

    function setCollectionForMintConfig(
        uint256 mintConfigId,
        address collection
    ) external;

    function setCardsPerPackForMintConfig(
        uint256 mintConfigId,
        uint256 cardsPerPack
    ) external;

    function setMaxPacksForMintConfig(
        uint256 mintConfigId,
        uint256 maxPacks
    ) external;

    function setPaymentTokenForMintConfig(
        uint256 mintConfigId,
        address paymentToken
    ) external;

    function setPriceForMintConfig(
        uint256 mintConfigId,
        uint256 price
    ) external;

    function setOnePerAddressForMintConfig(
        uint256 mintConfigId,
        bool onePerAddress
    ) external;

    function setRequiresWhitelistForMintConfig(
        uint256 mintConfigId,
        bool requiresWhitelist
    ) external;

    function setMerkleRootForMintConfig(
        uint256 mintConfigId,
        bytes32 merkleRoot
    ) external;

    function cancelMintConfig(uint256 mintConfigId) external;

    function setTreasury(address _treasury) external;

    function setExecutionDelegate(address _executionDelegate) external;

    // View functions to get config details might be included based on the requirement
    function getMintConfig(
        uint256 mintConfigId
    )
        external
        view
        returns (
            address collection,
            uint256 cardsPerPack,
            uint256 maxPacks,
            address paymentToken,
            uint256 price,
            bool onePerAddress,
            bool requiresWhitelist,
            bytes32 merkleRoot,
            uint256 expirationTimestamp,
            uint256 totalMintedPacks,
            bool cancelled
        );

    function getMintConfigHasMinted(
        uint256 mintConfigId,
        address user
    ) external view returns (bool);
}
