// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMinter {
    /// @notice Configuration for the vrgda calculation
    struct VRGDAConfig {
        int256 targetPrice; // Target price for a pack, to be scaled according to sales pace.
        int256 priceDecayPercent; // Percent price decays per unit of time with no sales, scaled by 1e18.
        int256 perTimeUnit; // The total number of packs to target selling every full unit of time.
    }

    // Events
    event NewMintConfig(
        uint256 mintConfigId,
        address collection,
        uint256 cardsPerPack,
        uint256 maxPacks,
        address paymentToken,
        uint256 fixedPrice,
        uint256 maxPacksPerAddress,
        bool requiresWhitelist,
        bytes32 merkleRoot,
        uint256 expirationTimestamp
    );
    event Mint(
        uint256 mintConfigId,
        address buyer,
        uint256 totalMintedPacks,
        uint256 firstTokenId,
        uint256 lastTokenId
    );
    event LevelUp(uint256[] burntTokenIds, uint256 mintedTokenId, address collection, address caller);
    event BurnToDraw(uint256[] burntTokenIds, uint256[] mintedTokenIds, address collection, address caller);
    event NewTreasury(address treasury);
    event CollectionUpdatedForMintConfig(uint256 mintConfigId, address newCollection);
    event CardsPerPackUpdatedForMintConfig(uint256 mintConfigId, uint256 newCardsPerPack);
    event MaxPacksUpdatedForMintConfig(uint256 mintConfigId, uint256 newMaxPacks);
    event PaymentTokenUpdatedForMintConfig(uint256 mintConfigId, address newPaymentToken);
    event FixedPriceUpdatedForMintConfig(uint256 mintConfigId, uint256 newFixedPrice);
    event VRGDAUpdatedForMintConfig(
        uint256 mintConfigId,
        int256 targetPrice,
        int256 priceDecayPercent,
        int256 perTimeUnit
    );
    event MaxPacksPerAddressUpdatedForMintConfig(uint256 mintConfigId, uint256 maxPacksPerAddress);
    event WhitelistRequirementUpdatedForMintConfig(uint256 mintConfigId, bool newRequiresWhitelist);
    event MerkleRootUpdatedForMintConfig(uint256 mintConfigId, bytes32 newMerkleRoot);
    event MintConfigCancelled(uint256 mintConfigId);
    event ExpirationTimestampUpdatedForMintConfig(uint256 mintConfigId, uint256 newExpirationTimestamp);

    // Functions
    function mint(uint256 configId, bytes32[] calldata merkleProof) external payable;

    function newMintConfig(
        address collection,
        uint256 cardsPerPack,
        uint256 maxPacks,
        address paymentToken,
        uint256 fixedPrice,
        uint256 maxPacksPerAddress,
        bool requiresWhitelist,
        bytes32 merkleRoot,
        uint256 startTimestamp,
        uint256 expirationTimestamp
    ) external;

    function levelUp(uint256[] calldata tokenIds, address collection) external;

    function setCollectionForMintConfig(uint256 mintConfigId, address collection) external;

    function setCardsPerPackForMintConfig(uint256 mintConfigId, uint256 cardsPerPack) external;

    function setMaxPacksForMintConfig(uint256 mintConfigId, uint256 maxPacks) external;

    function setPaymentTokenForMintConfig(uint256 mintConfigId, address paymentToken) external;

    function setFixedPriceForMintConfig(uint256 mintConfigId, uint256 fixedPrice) external;

    function setVRGDAForMintConfig(
        uint256 mintConfigId,
        int256 targetPrice,
        int256 priceDecayPercent,
        int256 perTimeUnit
    ) external;

    function setMaxPacksPerAddressForMintConfig(uint256 mintConfigId, uint256 maxPacksPerAddress) external;

    function setRequiresWhitelistForMintConfig(uint256 mintConfigId, bool requiresWhitelist) external;

    function setMerkleRootForMintConfig(uint256 mintConfigId, bytes32 merkleRoot) external;

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
            uint256 fixedPrice,
            uint256 maxPacksPerAddress,
            bool requiresWhitelist,
            bytes32 merkleRoot,
            uint256 startTimestamp,
            uint256 expirationTimestamp,
            uint256 totalMintedPacks,
            bool cancelled
        );

    function getAmountMintedPerAddressForMintConfig(uint256 mintConfigId, address user) external view returns (uint256);

    function saveFunds(address paymentToken, address to, uint256 amount) external;
}
