pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetRequiresWhitelistForMintConfig is BaseTest {
    struct MintConfig {
        address collection; // The collection address of the NFT
        uint256 cardsPerPack; // Number of cards per pack
        uint256 maxPacks; // Maximum number of packs available for minting
        address paymentToken; // Token used for payments (address(0) for ETH)
        uint256 price; // Price per pack
        bool onePerAddress; // Restrict to one mint per address
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
        mintConfig.onePerAddress = true;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.expirationTimestamp = 0;

        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.price,
            mintConfig.onePerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.expirationTimestamp
        );
    }

    function test_successful_setRequiresWhitelistForMintConfig() public {
        minter.setRequiresWhitelistForMintConfig(0, true);
        (, , , , , , bool actualRequiresWhitelist, , , , ) = minter.getMintConfig(
            0
        );
        assertTrue(actualRequiresWhitelist);
    }

    function test_unsuccessful_setRequiresWhitelistForMintConfig_notOwner()
        public
    {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: real error message
        minter.setRequiresWhitelistForMintConfig(0, true);
        cheats.stopPrank();
    }

    function test_unsuccessful_setRequiresWhitelistForMintConfig_invalid_mintConfigId()
        public
    {
        cheats.expectRevert("Invalid mintConfigId");
        minter.setRequiresWhitelistForMintConfig(1, true);
    }
}
