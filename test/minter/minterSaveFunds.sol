pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

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

    function test_mint_saveWETH() public {
        MintConfig memory mintConfig;
        mintConfig.fixedPrice = 1 ether;

        cheats.startPrank(user1);
        weth.getFaucet(mintConfig.fixedPrice);
        weth.transfer(address(minter), mintConfig.fixedPrice);
        assertEq(weth.balanceOf(address(minter)), mintConfig.fixedPrice);
        cheats.stopPrank();

        minter.saveFunds(address(weth), user1, mintConfig.fixedPrice);
        assertEq(weth.balanceOf(address(minter)), 0);
    }
}
