pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract Mint_fuzz is BaseTest {
    struct MintConfig {
        address collection; // The collection address of the NFT
        uint256 cardsPerPack; // Number of cards per pack
        uint256 totalPacks; // Total number of packs available for minting
        address paymentToken; // Token used for payments (address(0) for ETH)
        uint256 price; // Price per pack
        bool onePerAddress; // Restrict to one mint per address
        bool requiresWhitelist; // If true, requires user to be whitelisted
        bytes32 merkleRoot; // Root of Merkle tree for whitelist verification
        uint256 expirationTimestamp; // Expiration timestamp for minting
    }

    function setUp() public override {
        super.setUp();
    }

    function test_mint_ERC20_fuzz(
        uint256 _cardPerPack,
        uint256 _price,
        uint256 _totalPacks
    ) public {
        if (_cardPerPack > 200 || _cardPerPack < 1) return;
        if (_price > 120000000 ether) return;
        if (_totalPacks < 1) return;

        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = _cardPerPack;
        mintConfig.totalPacks = _totalPacks;
        mintConfig.paymentToken = address(weth);
        mintConfig.price = _price;
        mintConfig.onePerAddress = true;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.expirationTimestamp = 0;

        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.totalPacks,
            mintConfig.paymentToken,
            mintConfig.price,
            mintConfig.onePerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.expirationTimestamp
        );

        cheats.startPrank(user1);
        weth.getFaucet(mintConfig.price);
        weth.approve(address(executionDelegate), mintConfig.price);
        cheats.stopPrank();

        cheats.startPrank(user1);
        minter.mint(0, new bytes32[](0));
        cheats.stopPrank();

        assertEq(fantasyCards.balanceOf(user1), mintConfig.cardsPerPack);
        assertEq(weth.balanceOf(user1), 0);
        assertEq(weth.balanceOf(address(treasury)), mintConfig.price);
    }

    function test_mint_ETH_fuzz(
        uint256 _cardPerPack,
        uint256 _price,
        uint256 _totalPacks
    ) public {
        if (_cardPerPack > 200 || _cardPerPack < 1) return;
        if (_price > 120000000 ether) return;
        if (_totalPacks < 1) return;

        MintConfig memory mintConfig;
        mintConfig.collection = address(fantasyCards);
        mintConfig.cardsPerPack = _cardPerPack;
        mintConfig.totalPacks = 1;
        mintConfig.paymentToken = address(0);
        mintConfig.price = _price;
        mintConfig.onePerAddress = true;
        mintConfig.requiresWhitelist = false;
        mintConfig.merkleRoot = bytes32(0);
        mintConfig.expirationTimestamp = 0;

        minter.newMintConfig(
            mintConfig.collection,
            mintConfig.cardsPerPack,
            mintConfig.totalPacks,
            mintConfig.paymentToken,
            mintConfig.price,
            mintConfig.onePerAddress,
            mintConfig.requiresWhitelist,
            mintConfig.merkleRoot,
            mintConfig.expirationTimestamp
        );

        cheats.deal(user1, mintConfig.price);

        cheats.startPrank(user1);
        minter.mint{value: mintConfig.price}(0, new bytes32[](0));
        cheats.stopPrank();

        assertEq(fantasyCards.balanceOf(user1), mintConfig.cardsPerPack);
        assertEq(address(treasury).balance, mintConfig.price);
    }
}
