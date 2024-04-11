pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";
import "../helpers/TraderContract.sol";

contract Mint is BaseTest {
    struct MintConfig {
        address collection; // The collection address of the NFT
        uint256 cardsPerPack; // Number of cards per pack
        uint256 maxPacks; // Total number of packs available for minting
        address paymentToken; // Token used for payments (address(0) for ETH)
        uint256 fixedPrice; // Price per pack
        uint256 maxPacksPerAddress; // max number of packs that can be minted by the same address
        bool requiresWhitelist; // If true, requires user to be whitelisted
        bytes32 merkleRoot; // Root of Merkle tree for whitelist verification
        uint256 startTimestamp; // Start timestamp for minting
        uint256 expirationTimestamp; // Expiration timestamp for minting
    }

    function setUp() public override {
        super.setUp();
    }

    function test_mint_ERC20() public {
        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = 80;
        mintConfig.maxPacks = 1;
        mintConfig.paymentToken = address(weth);
        mintConfig.fixedPrice = 1 ether;
        mintConfig.maxPacksPerAddress = 0;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.startTimestamp = block.timestamp;
        mintConfig.expirationTimestamp = 0;

        cheats.startPrank(mintConfigMaster);
        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.fixedPrice,
            mintConfig.maxPacksPerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.startTimestamp,
            mintConfig.expirationTimestamp
        );
        cheats.stopPrank();

        cheats.startPrank(user1);
        weth.getFaucet(mintConfig.fixedPrice);
        weth.approve(address(executionDelegate), mintConfig.fixedPrice);
        cheats.stopPrank();

        cheats.startPrank(user1, user1);
        minter.mint(0, new bytes32[](0));
        cheats.stopPrank();

        assertEq(fantasyCards.balanceOf(user1), mintConfig.cardsPerPack);
        assertEq(weth.balanceOf(user1), 0);
        assertEq(weth.balanceOf(address(treasury)), mintConfig.fixedPrice);
    }

    function test_mint_ETH() public {
        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = 50;
        mintConfig.maxPacks = 1;
        mintConfig.paymentToken = address(0);
        mintConfig.fixedPrice = 1 ether;
        mintConfig.maxPacksPerAddress = 0;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.startTimestamp = block.timestamp;

        mintConfig.expirationTimestamp = 0;

        cheats.startPrank(mintConfigMaster);
        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.fixedPrice,
            mintConfig.maxPacksPerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.startTimestamp,
            mintConfig.expirationTimestamp
        );
        cheats.stopPrank();

        cheats.deal(user1, mintConfig.fixedPrice);

        cheats.startPrank(user1, user1);
        minter.mint{value: mintConfig.fixedPrice}(0, new bytes32[](0));
        cheats.stopPrank();

        assertEq(fantasyCards.balanceOf(user1), mintConfig.cardsPerPack);
        assertEq(address(treasury).balance, mintConfig.fixedPrice);
    }

    function test_successful_mint_whitelist() public {
        // Merkle root and proof generated using js
        bytes32 merkleRoot = 0x537f750e9bc761acf4c8ee26659c634f7038eb65788aeb6b0d9f03513dfd69cb; // Merkle root of user1 address and 2 others randomly generated
        bytes32[] memory merkleProof = new bytes32[](2); // Merkle proof for user1 address
        merkleProof[0] = 0x8d213e32ad22097ec7004e907bfef6d0b722b202f28b41405980148f2fb6428e;
        merkleProof[1] = 0xd066834ad2b82e26c46bee97cee6fbd4b1e7a43183256e5977e6b0a89830b5ee;

        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = 20;
        mintConfig.maxPacks = 1;
        mintConfig.paymentToken = address(weth);
        mintConfig.fixedPrice = 1 ether;
        mintConfig.maxPacksPerAddress = 0;
        mintConfig.requiresWhitelist = true;
        mintConfig.merkleRoot = merkleRoot;
        mintConfig.startTimestamp = block.timestamp;

        mintConfig.expirationTimestamp = 0;

        cheats.startPrank(mintConfigMaster);
        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.fixedPrice,
            mintConfig.maxPacksPerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.startTimestamp,
            mintConfig.expirationTimestamp
        );
        cheats.stopPrank();

        cheats.startPrank(user1);
        weth.getFaucet(mintConfig.fixedPrice);
        weth.approve(address(executionDelegate), mintConfig.fixedPrice);
        cheats.stopPrank();

        cheats.startPrank(user1, user1);
        minter.mint(0, merkleProof);
        cheats.stopPrank();

        assertEq(fantasyCards.balanceOf(user1), mintConfig.cardsPerPack);
        assertEq(weth.balanceOf(user1), 0);
        assertEq(weth.balanceOf(address(treasury)), mintConfig.fixedPrice);
    }

    function test_unsuccessful_mint_mintConfig_cancelled() public {
        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = 50;
        mintConfig.maxPacks = 1;
        mintConfig.paymentToken = address(0);
        mintConfig.fixedPrice = 1 ether;
        mintConfig.maxPacksPerAddress = 0;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.startTimestamp = block.timestamp;

        mintConfig.expirationTimestamp = 0;

        cheats.startPrank(mintConfigMaster);
        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.fixedPrice,
            mintConfig.maxPacksPerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.startTimestamp,
            mintConfig.expirationTimestamp
        );
        cheats.stopPrank();

        cheats.startPrank(mintConfigMaster);
        minter.cancelMintConfig(0);
        cheats.stopPrank();

        cheats.deal(user1, mintConfig.fixedPrice);

        cheats.startPrank(user1, user1);
        cheats.expectRevert("Mint config cancelled");
        minter.mint{value: mintConfig.fixedPrice}(0, new bytes32[](0));
        cheats.stopPrank();
    }

    function test_unauthorised_mint_whitelist() public {
        // Merkle root and proof generated using js
        bytes32 merkleRoot = 0x537f750e9bc761acf4c8ee26659c634f7038eb65788aeb6b0d9f03513dfd69cb; // Merkle root of user1 address and 2 others randomly generated
        bytes32[] memory merkleProof = new bytes32[](2); // Merkle proof for user1 address
        merkleProof[0] = 0x8d213e32ad22097ec7004e907bfef6d0b722b202f28b41405980148f2fb6428e;
        merkleProof[1] = 0xd066834ad2b82e26c46bee97cee6fbd4b1e7a43183256e5977e6b0a89830b5ee;

        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = 3;
        mintConfig.maxPacks = 1;
        mintConfig.paymentToken = address(weth);
        mintConfig.fixedPrice = 1 ether;
        mintConfig.maxPacksPerAddress = 0;
        mintConfig.requiresWhitelist = true;
        mintConfig.merkleRoot = merkleRoot;
        mintConfig.startTimestamp = block.timestamp;

        mintConfig.expirationTimestamp = 0;

        cheats.startPrank(mintConfigMaster);
        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.fixedPrice,
            mintConfig.maxPacksPerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.startTimestamp,
            mintConfig.expirationTimestamp
        );
        cheats.stopPrank();

        cheats.startPrank(user2, user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.expectRevert("User not whitelisted");
        minter.mint(0, merkleProof);
        cheats.stopPrank();
    }

    function test_maxPacksPerAddress_restriction() public {
        // Test that the onePerAddress restriction works
        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = 3;
        mintConfig.maxPacks = 100;
        mintConfig.paymentToken = address(0);
        mintConfig.fixedPrice = 1 ether;
        mintConfig.maxPacksPerAddress = 1;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.startTimestamp = block.timestamp;

        mintConfig.expirationTimestamp = 0;

        cheats.startPrank(mintConfigMaster);
        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.fixedPrice,
            mintConfig.maxPacksPerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.startTimestamp,
            mintConfig.expirationTimestamp
        );
        cheats.stopPrank();

        cheats.deal(user1, mintConfig.fixedPrice * 100);

        cheats.startPrank(user1, user1);
        minter.mint{value: mintConfig.fixedPrice}(0, new bytes32[](0));
        cheats.expectRevert("User reached max mint limit");
        minter.mint{value: mintConfig.fixedPrice}(0, new bytes32[](0));
        cheats.stopPrank();
    }

    function test_unseccessful_mint_when_sold_out() public {
        // Test minting when no packs are left
        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = 3;
        mintConfig.maxPacks = 1;
        mintConfig.paymentToken = address(0);
        mintConfig.fixedPrice = 1 ether;
        mintConfig.maxPacksPerAddress = 0;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.startTimestamp = block.timestamp;

        mintConfig.expirationTimestamp = 0;

        cheats.startPrank(mintConfigMaster);
        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.fixedPrice,
            mintConfig.maxPacksPerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.startTimestamp,
            mintConfig.expirationTimestamp
        );
        cheats.stopPrank();

        cheats.deal(user1, mintConfig.fixedPrice * 100);

        cheats.startPrank(user1, user1);
        minter.mint{value: mintConfig.fixedPrice}(0, new bytes32[](0));
        cheats.stopPrank();

        cheats.startPrank(user1, user1);
        cheats.expectRevert("No packs left");
        minter.mint{value: mintConfig.fixedPrice}(0, new bytes32[](0));
        cheats.stopPrank();
    }

    function test_unsuccessful_mint_when_expired() public {
        // Test minting when mintConfig is expired
        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = 3;
        mintConfig.maxPacks = 1;
        mintConfig.paymentToken = address(0);
        mintConfig.fixedPrice = 1 ether;
        mintConfig.maxPacksPerAddress = 0;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.startTimestamp = block.timestamp;
        mintConfig.expirationTimestamp = block.timestamp + 100;

        cheats.startPrank(mintConfigMaster);
        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.maxPacks,
            mintConfig.paymentToken,
            mintConfig.fixedPrice,
            mintConfig.maxPacksPerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.startTimestamp,
            mintConfig.expirationTimestamp
        );
        cheats.stopPrank();

        vm.warp(mintConfig.expirationTimestamp + 101);

        cheats.deal(user1, mintConfig.fixedPrice);

        cheats.startPrank(user1, user1);
        cheats.expectRevert("Mint config expired");
        minter.mint{value: mintConfig.fixedPrice}(0, new bytes32[](0));
        cheats.stopPrank();
    }

    function test_unsuccessful_mint_not_EOA() public {
        // DEPLOY TRADER CONTRACT
        TraderContract traderContract = new TraderContract(address(exchange), address(minter));

        cheats.expectRevert("Function can only be called by an EOA");
        traderContract.mintOnMinter(0, new bytes32[](0));
    }
}
