pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract Mint_fuzz is BaseTest {
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

    function test_mint_ERC20_fuzz(
        uint256 _cardPerPack,
        uint256 _fixedPrice,
        uint256 _maxPacks,
        uint256 _maxPacksPerAddress
    ) public {
        if (_cardPerPack > 200 || _cardPerPack < 1) return;
        if (_fixedPrice > 120000000 ether) return;
        if (_fixedPrice == 0) return;
        if (_maxPacks < 1) return;
        if (_maxPacksPerAddress < 1) return;

        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = _cardPerPack;
        mintConfig.maxPacks = _maxPacks;
        mintConfig.paymentToken = address(weth);
        mintConfig.fixedPrice = _fixedPrice;
        mintConfig.maxPacksPerAddress = _maxPacksPerAddress;
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
        minter.mint(0, new bytes32[](0), 120000000 ether);
        cheats.stopPrank();

        assertEq(fantasyCards.balanceOf(user1), mintConfig.cardsPerPack);
        assertEq(weth.balanceOf(user1), 0);
        assertEq(weth.balanceOf(address(treasury)), mintConfig.fixedPrice);
    }

    function test_mint_ETH_fuzz(
        uint256 _cardPerPack,
        uint256 _fixedPrice,
        uint256 _maxPacks,
        uint256 _maxPacksPerAddress
    ) public {
        if (_cardPerPack > 200 || _cardPerPack < 1) return;
        if (_fixedPrice > 120000000 ether) return;
        if (_fixedPrice == 0) return;
        if (_maxPacks < 1) return;
        if (_maxPacksPerAddress < 1) return;

        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = _cardPerPack;
        mintConfig.maxPacks = 1;
        mintConfig.paymentToken = address(0);
        mintConfig.fixedPrice = _fixedPrice;
        mintConfig.maxPacksPerAddress = _maxPacksPerAddress;
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
        minter.mint{value: mintConfig.fixedPrice}(0, new bytes32[](0), 120000000 ether);
        cheats.stopPrank();

        assertEq(fantasyCards.balanceOf(user1), mintConfig.cardsPerPack);
        assertEq(address(treasury).balance, mintConfig.fixedPrice);
    }
}
