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

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IBlast.sol";
import "./interfaces/IExecutionDelegate.sol";
import "./interfaces/IFantasyCards.sol";
import "./interfaces/IMinter.sol";

/// @title A contract for minting Fantasy Cards
/// @dev Inherits from Ownable for ownership management
contract Minter is IMinter, AccessControlDefaultAdminRules, ReentrancyGuard {
    /// @notice Configuration for a mint operation
    struct MintConfig {
        address collection; // The collection address of the NFT
        uint256 cardsPerPack; // Number of cards per pack
        uint256 maxPacks; // Total number of packs available for minting
        address paymentToken; // Token used for payments (address(0) for ETH)
        uint256 price; // Price per pack
        bool onePerAddress; // Restrict to one mint per address
        bool requiresWhitelist; // If true, requires user to be whitelisted
        bytes32 merkleRoot; // Root of Merkle tree for whitelist verification
        uint256 expirationTimestamp; // Expiration timestamp for the mint config
        mapping(address => bool) hasMinted; // Tracks addresses that have minted
        uint256 totalMintedPacks; // Total number of packs minted
        bool cancelled; // If true, mint config has been cancelled
    }

    /// @notice Role hash for the address allowed to cancel mintConfigs
    bytes32 public constant CANCELER_ROLE =
        keccak256("CANCELER_ROLE");

    /* Variables */
    mapping(uint256 mintConfigId => MintConfig) public mintConfigs;
    address public treasury;
    IExecutionDelegate public executionDelegate;
    uint256 public mintConfigIdCounter;

    /**
     * @dev Initializes the contract with treasury and execution delegate addresses.
     * @param _treasury Treasury address.
     * @param _executionDelegate Execution delegate address.
     */
    constructor(
        address _treasury,
        address _executionDelegate
    ) AccessControlDefaultAdminRules(0, msg.sender) {
        // REVIEW: When this contract is live
        // IBlast(0x4300000000000000000000000000000000000002)
        //     .configureClaimableGas();
        // IBlast(0x4300000000000000000000000000000000000002).configureGovernor(
        //     msg.sender
        // );
        _setTreasury(_treasury);
        _setExecutionDelegate(_executionDelegate);
    }

    /**
     * @notice Mints packs based on the specified mint configuration
     * @dev Requires the mint configuration not to be cancelled, the user to be whitelisted (if applicable), and not to have minted before (if applicable). Transfers the payment and mints the NFTs.
     * @param configId ID of the mint configuration to use
     * @param merkleProof Proof for whitelist verification, if required
     */
    function mint(
        uint256 configId,
        bytes32[] calldata merkleProof
    ) public payable nonReentrant {
        MintConfig storage mintConfig = mintConfigs[configId];
        require(mintConfig.expirationTimestamp == 0 || mintConfig.expirationTimestamp > block.timestamp, "Mint config expired");
        require(!mintConfig.cancelled, "Mint config cancelled");
        require(
            !mintConfig.requiresWhitelist ||
                _verifyWhitelist(
                    mintConfig.merkleRoot,
                    merkleProof,
                    msg.sender
                ),
            "User not whitelisted"
        );
        require(
            !mintConfig.onePerAddress || !mintConfig.hasMinted[msg.sender],
            "User already minted"
        );
        require(
            mintConfig.maxPacks > mintConfig.totalMintedPacks,
            "No packs left"
        );

        mintConfig.totalMintedPacks += 1;
        if (mintConfig.onePerAddress) {
            mintConfig.hasMinted[msg.sender] = true;
        }


        _executeFundsTransfer(
            mintConfig.paymentToken,
            msg.sender,
            treasury,
            mintConfig.price
        );

        _executeBatchMint(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            msg.sender
        );

        emit Mint(configId, msg.sender, mintConfig.totalMintedPacks);
    }

    /**
     * @notice Creates a new mint configuration
     * @dev Only callable by the contract owner. Emits a NewMintConfig event upon success.
     * @param collection Address of the NFT collection for the packs
     * @param cardsPerPack Number of cards in each pack
     * @param maxPacks Maximum number of packs available for this configuration
     * @param paymentToken Token used for payments (address(0) for ETH)
     * @param price Price per pack in the specified payment token
     * @param onePerAddress Restrict to one mint per address if true
     * @param requiresWhitelist Require users to be whitelisted if true
     * @param merkleRoot Root of Merkle tree for whitelist verification
     * @param expirationTimestamp Expiration timestamp for the mint config
     */
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
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(collection != address(0), "Collection address cannot be 0x0");
        require(cardsPerPack > 0, "Cards per pack must be greater than 0");
        require(maxPacks > 0, "Max packs must be greater than 0");

        MintConfig storage config = mintConfigs[mintConfigIdCounter];
        config.collection = collection;
        config.cardsPerPack = cardsPerPack;
        config.maxPacks = maxPacks;
        config.paymentToken = paymentToken;
        config.price = price;
        config.onePerAddress = onePerAddress;
        config.requiresWhitelist = requiresWhitelist;
        config.merkleRoot = merkleRoot;
        config.expirationTimestamp = expirationTimestamp;

        emit NewMintConfig(
            mintConfigIdCounter,
            collection,
            cardsPerPack,
            maxPacks,
            paymentToken,
            price,
            onePerAddress,
            requiresWhitelist,
            merkleRoot,
            expirationTimestamp
        );

        mintConfigIdCounter++;
    }

    /**
     * @notice Updates the NFT collection address for a specific mint configuration
     * @dev Only callable by the contract owner.
     * @param mintConfigId The ID of the mint configuration to update
     * @param collection The new collection address
     */
    function setCollectionForMintConfig(
        uint256 mintConfigId,
        address collection
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");
        require(
            collection != address(0),
            "Collection address cannot the zero address"
        );

        MintConfig storage config = mintConfigs[mintConfigId];
        config.collection = collection;

        emit CollectionUpdatedForMintConfig(mintConfigId, collection);
    }

    /**
     * @notice Updates the number of cards per pack for a specific mint configuration
     * @dev Only callable by the contract owner.
     * @param mintConfigId The ID of the mint configuration to update
     * @param cardsPerPack The new number of cards per pack
     */
    function setCardsPerPackForMintConfig(
        uint256 mintConfigId,
        uint256 cardsPerPack
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");
        require(cardsPerPack > 0, "Cards per pack must be greater than 0");
        MintConfig storage config = mintConfigs[mintConfigId];
        config.cardsPerPack = cardsPerPack;

        emit CardsPerPackUpdatedForMintConfig(mintConfigId, cardsPerPack);
    }

    /**
     * @notice Updates the total number of packs for a specific mint configuration
     * @dev Only callable by the contract owner.
     * @param mintConfigId The ID of the mint configuration to update
     * @param maxPacks The maximum number of packs available
     */
    function setMaxPacksForMintConfig(
        uint256 mintConfigId,
        uint256 maxPacks
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");
        require(maxPacks > 0, "Maximum packs must be greater than 0");
        MintConfig storage config = mintConfigs[mintConfigId];
        config.maxPacks = maxPacks;

        emit MaxPacksUpdatedForMintConfig(mintConfigId, maxPacks);
    }

    /**
     * @notice Updates the payment token for a specific mint configuration
     * @dev Only callable by the contract owner.
     * @param mintConfigId The ID of the mint configuration to update
     * @param paymentToken The new payment token address
     */
    function setPaymentTokenForMintConfig(
        uint256 mintConfigId,
        address paymentToken
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");
        MintConfig storage config = mintConfigs[mintConfigId];
        config.paymentToken = paymentToken;

        emit PaymentTokenUpdatedForMintConfig(mintConfigId, paymentToken);
    }

    /**
     * @notice Updates the price per pack for a specific mint configuration
     * @dev Only callable by the contract owner.
     * @param mintConfigId The ID of the mint configuration to update
     * @param price The new price per pack
     */
    function setPriceForMintConfig(
        uint256 mintConfigId,
        uint256 price
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");
        MintConfig storage config = mintConfigs[mintConfigId];
        config.price = price;

        emit PriceUpdatedForMintConfig(mintConfigId, price);
    }

    /**
     * @notice Updates the one per address restriction for a specific mint configuration
     * @dev Only callable by the contract owner.
     * @param mintConfigId The ID of the mint configuration to update
     * @param onePerAddress The new one per address restriction state
     */
    function setOnePerAddressForMintConfig(
        uint256 mintConfigId,
        bool onePerAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");
        MintConfig storage config = mintConfigs[mintConfigId];
        config.onePerAddress = onePerAddress;

        emit OnePerAddressUpdatedForMintConfig(mintConfigId, onePerAddress);
    }

    /**
     * @notice Updates the whitelist requirement for a specific mint configuration
     * @dev Only callable by the contract owner.
     * @param mintConfigId The ID of the mint configuration to update
     * @param requiresWhitelist The new whitelist requirement state
     */
    function setRequiresWhitelistForMintConfig(
        uint256 mintConfigId,
        bool requiresWhitelist
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");
        MintConfig storage config = mintConfigs[mintConfigId];
        config.requiresWhitelist = requiresWhitelist;

        emit WhitelistRequirementUpdatedForMintConfig(
            mintConfigId,
            requiresWhitelist
        );
    }

    /**
     * @notice Updates the merkle root for whitelist verification for a specific mint configuration
     * @dev Only callable by the contract owner.
     * @param mintConfigId The ID of the mint configuration to update
     * @param merkleRoot The new merkle root for whitelist verification
     */
    function setMerkleRootForMintConfig(
        uint256 mintConfigId,
        bytes32 merkleRoot
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");
        require(merkleRoot != bytes32(0), "Invalid merkleRoot");

        MintConfig storage config = mintConfigs[mintConfigId];
        config.merkleRoot = merkleRoot;

        emit MerkleRootUpdatedForMintConfig(mintConfigId, merkleRoot);
    }
    
    function setExpirationTimestampForMintConfig(
        uint256 mintConfigId,
        uint256 expirationTimestamp
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");
        
        MintConfig storage config = mintConfigs[mintConfigId];
        config.expirationTimestamp = expirationTimestamp;

        emit ExpirationTimestampUpdatedForMintConfig(mintConfigId, expirationTimestamp);
    }

    /**
     * @notice Cancels a specific mint configuration, preventing further minting
     * @param mintConfigId The ID of the mint configuration to cancel
     */
    function cancelMintConfig(uint256 mintConfigId) public onlyRole(CANCELER_ROLE) {
        require(mintConfigId < mintConfigIdCounter, "Invalid mintConfigId");

        MintConfig storage config = mintConfigs[mintConfigId];
        config.cancelled = true;

        emit MintConfigCancelled(mintConfigId);
    }

    /**
     * @notice Sets a new treasury address for collecting payments from minting operations.
     * @param _treasury The address of the new treasury. Must be a non-zero address.
     */
    function setTreasury(address _treasury) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTreasury(_treasury);
    }

    /**
     * @notice Updates the execution delegate address.
     * @param _executionDelegate New delegate address.
     */
    function setExecutionDelegate(address _executionDelegate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setExecutionDelegate(_executionDelegate);
    }

    /**
     * @notice Retrieves details of a specific mint configuration
     * @param mintConfigId The ID of the mint configuration to retrieve
     * @return collection The NFT collection address
     * @return cardsPerPack The number of cards per pack
     * @return maxPacks The maximum number of packs available
     * @return paymentToken The token used for payments
     * @return price The price per pack
     * @return onePerAddress The one per address restriction state
     * @return requiresWhitelist The whitelist requirement state
     * @return merkleRoot The merkle root for whitelist verification
     * @return totalMintedPacks The total number of packs minted
     * @return cancelled The cancellation state of the mint configuration
     */
    function getMintConfig(
        uint256 mintConfigId
    )
        public
        view
        returns (
            address,
            uint256,
            uint256,
            address,
            uint256,
            bool,
            bool,
            bytes32,
            uint256,
            uint256,
            bool
        )
    {
        MintConfig storage config = mintConfigs[mintConfigId];
        return (
            config.collection,
            config.cardsPerPack,
            config.maxPacks,
            config.paymentToken,
            config.price,
            config.onePerAddress,
            config.requiresWhitelist,
            config.merkleRoot,
            config.expirationTimestamp,
            config.totalMintedPacks,
            config.cancelled
        );
    }

    /**
     * @notice Checks if a user has already minted from a specific mint configuration
     * @param mintConfigId The ID of the mint configuration to check
     * @param user The address of the user to check
     * @return hasMinted Whether the user has already minted
     */
    function getMintConfigHasMinted(
        uint256 mintConfigId,
        address user
    ) public view returns (bool) {
        MintConfig storage config = mintConfigs[mintConfigId];
        return config.hasMinted[user];
    }

    /**
     * @notice Internal function that sets a new treasury address for collecting payments from minting operations.
     * @param _treasury The address of the new treasury. Must be a non-zero address.
     */
    function _setTreasury(address _treasury) internal {
        require(_treasury != address(0), "Treasury address cannot be 0x0");
        treasury = _treasury;

        emit NewTreasury(_treasury);
    }

    /**
     * @notice Internal function that updates the execution delegate address.
     * @param _executionDelegate New delegate address.
     */
    function _setExecutionDelegate(address _executionDelegate) internal {
        require(_executionDelegate != address(0), "Execution delegate address cannot be 0x0");
        executionDelegate = IExecutionDelegate(_executionDelegate);
    }

    /**
     * @dev Checks if user is whitelisted via Merkle proof.
     * @param merkleRoot Root of Merkle tree.
     * @param merkleProof Merkle proof for user.
     * @param user User's address to check.
     * @return isWhitelisted True if whitelisted, else false.
     */
    function _verifyWhitelist(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        address user
    ) internal pure returns (bool isWhitelisted) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev Transfers funds or Ether based on the payment type.
     * @param paymentToken Token contract address, or zero for Ether.
     * @param from Sender's address.
     * @param to Recipient's address.
     * @param amount Amount to transfer.
     */
    function _executeFundsTransfer(
        address paymentToken,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (paymentToken == address(0)) {
            require(msg.value == amount, "Incorrect ETH amount");
        }
        /* Transfer remainder to seller. */
        _transferTo(paymentToken, from, to, amount);
    }

    /**
     * @dev Transfers Ether or ERC20 tokens from one address to another.
     * @param paymentToken ERC20 token address, or zero for Ether.
     * @param from Sender's address.
     * @param to Recipient's address.
     * @param amount Transfer amount.
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
            payable(to).transfer(amount);
        } else {
            executionDelegate.transferERC20(paymentToken, from, to, amount);
        }
    }

    /**
     * @dev Mints multiple cards to a buyer's address.
     * @param collection NFT collection address.
     * @param cardsPerPack Quantity of cards to mint.
     * @param buyer Recipient address.
     */
    function _executeBatchMint(
        address collection,
        uint256 cardsPerPack,
        address buyer
    ) internal {
        for (uint256 i = 0; i < cardsPerPack; i++) {
            executionDelegate.mintFantasyCard(collection, buyer);
        }
    }
    
    /**
     * @dev Function to retrieve funds mistakenly sent to the mint contract.
     * @param paymentToken ERC20 token address, or zero for Ether.
     * @param to Recipient's address.
     * @param amount Transfer amount.
     */
    function saveFunds(address paymentToken, address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _transferTo(paymentToken, address(this), to, amount);
    }
}
