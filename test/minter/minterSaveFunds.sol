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
        uint256 amount = 1 ether;

        cheats.startPrank(user1);
        weth.getFaucet(amount);
        weth.transfer(address(minter), amount);
        assertEq(weth.balanceOf(address(minter)), amount);
        cheats.stopPrank();

        minter.saveFunds(address(weth), user1, amount);
        assertEq(weth.balanceOf(address(minter)), 0);
    }

    function test_mint_saveETH() public {
        cheats.deal(address(minter), 1 ether);
        assertEq((address(minter)).balance, 1 ether);
        minter.saveFunds(address(0), user1, 1 ether);
        assertEq((address(minter)).balance, 0);
    }
}
