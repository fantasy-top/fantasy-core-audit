pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetCollectionForMintConfig is BaseTest {
    struct MintConfig {
        address collection; // The collection address of the NFT
        uint256 cardsPerPack; // Number of cards per pack
        uint256 maxPacks; // Total number of packs available for minting
        address paymentToken; // Token used for payments (address(0) for ETH)
        uint256 price; // Price per pack
        uint256 maxPacksPerAddress; // max number of packs that can be minted by the same address
        bool requiresWhitelist; // If true, requires user to be whitelisted
        bytes32 merkleRoot; // Root of Merkle tree for whitelist verification
        uint256 expirationTimestamp; // Expiration timestamp for minting
    }

    function setUp() public override {
        super.setUp();

        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = 80;
        mintConfig.maxPacks = 1;
        mintConfig.paymentToken = address(weth);
        mintConfig.price = 1 ether;
        mintConfig.maxPacksPerAddress = 0;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.expirationTimestamp = 0;

        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.price,
            mintConfig.maxPacksPerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.expirationTimestamp
        );
    }

    function test_successful_setCollectionForMintConfig() public {
        minter.setCollectionForMintConfig(0, address(0x123));
        (address actualCollection, , , , , , , , , , ) = minter.getMintConfig(0);
        assertEq(actualCollection, address(0x123));
    }

    function test_unsuccessful_setCollectionForMintConfig_notOwner() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: real error message
        minter.setCollectionForMintConfig(0, address(0x123));
        cheats.stopPrank();
    }

    function test_unsuccessful_setCollectionForMintConfig_zero() public {
        cheats.expectRevert("Collection address cannot the zero address");
        minter.setCollectionForMintConfig(0, address(0));
    }

    function test_unsuccessful_setCollectionForMintConfig_invalid_mintConfigId()
        public
    {
        cheats.expectRevert("Invalid mintConfigId");
        minter.setCollectionForMintConfig(1, address(0x123));
    }
}
