pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";
import "../../src/interfaces/IMinter.sol";
// import console
import "../../lib/forge-std/src/console.sol";

contract Mint is BaseTest {
    struct VRGDAConfig {
        int256 targetPrice; // Target price for a pack, to be scaled according to sales pace.
        int256 priceDecayPercent; // Percent price decays per unit of time with no sales, scaled by 1e18.
        int256 perTimeUnit; // The total number of packs to target selling every full unit of time.
    }

    struct MintConfig {
        address collection; // The collection address of the NFT
        uint256 cardsPerPack; // Number of cards per pack
        uint256 maxPacks; // Total number of packs available for minting
        address paymentToken; // Token used for payments (address(0) for ETH)
        uint256 fixedPrice; // Fixed price for a pack (0 for VRGDA)
        uint256 maxPacksPerAddress; // max number of packs that can be minted by the same address
        bool requiresWhitelist; // If true, requires user to be whitelisted
        bytes32 merkleRoot; // Root of Merkle tree for whitelist verification
        uint256 startTimestamp; // Start time for the mint config
        uint256 expirationTimestamp; // Expiration timestamp for minting
        uint256 totalMintedPacks; // Total number of packs minted
        bool cancelled; // If true, mint config is cancelled
    }

    function setUp() public override {
        super.setUp();
    }

    function test_mint_ETH() public {
        MintConfig memory mintConfig = MintConfig({
            collection: address(fantasyCards),
            cardsPerPack: 50,
            maxPacks: 100,
            paymentToken: address(0),
            fixedPrice: 1,
            maxPacksPerAddress: 10,
            requiresWhitelist: false,
            merkleRoot: bytes32(0),
            startTimestamp: block.timestamp - 100,
            expirationTimestamp: block.timestamp + 10 days,
            totalMintedPacks: 0,
            cancelled: false
        });

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

        uint256 mintConfigId = 0;
        // the target price
        int256 targetPrice = 1 ether;
        // price drops by 30% every minute without sales
        int256 priceDecayPercent = 3e17;
        // we want to sell 2 packs per minutes
        int256 perTimeUnit = 2e18;

        cheats.deal(user1, 100 ether);

        // TEST: fixed price works
        cheats.startPrank(user1);
        uint256 price = minter.getPackPrice(mintConfigId);
        assertEq(price, mintConfig.fixedPrice);
        cheats.stopPrank();

        // TEST: check that fixed price is set to 0 after setting VRGDA
        minter.setVRGDAForMintConfig(mintConfigId, targetPrice, priceDecayPercent, perTimeUnit);
        (, , , , uint256 fixedPrice, , , , , , , ) = minter.getMintConfig(mintConfigId);
        assertEq(fixedPrice, 0);

        cheats.startPrank(user1, user1);

        // TEST: after a mint event the price increases
        minter.mint{value: price1}(mintConfigId, new bytes32[](0));
        uint256 price2 = minter.getPackPrice(mintConfigId);
        assert(price2 > price1);

        // TEST: if sales on time the price stays the same
        minter.mint{value: price2}(mintConfigId, new bytes32[](0));
        vm.warp(block.timestamp + 1 minutes);
        uint256 price3 = minter.getPackPrice(mintConfigId);
        assertEq(price1, price3);

        // TEST: the price stays consistent with values from yesterday
        minter.mint{value: price1}(mintConfigId, new bytes32[](0));
        uint256 price4 = minter.getPackPrice(mintConfigId);
        assertEq(price2, price4);

        minter.mint{value: price2}(mintConfigId, new bytes32[](0));

        // TEST: after a day without sales the price drops by priceDecayPercent
        vm.warp(block.timestamp + 2 minutes);
        uint256 price5 = minter.getPackPrice(mintConfigId);
        uint256 expectedPrice = (price1 * (1e18 - uint256(priceDecayPercent))) / 1e18;
        // max difference of 1 wei
        assertApproxEqAbs(expectedPrice, price5, 1);
        // rounds up
        assert(price5 > expectedPrice);
        cheats.stopPrank();
    }

    function test_mint_USDC() public {
        MintConfig memory mintConfig = MintConfig({
            collection: address(fantasyCards),
            cardsPerPack: 50,
            maxPacks: 100,
            paymentToken: address(usdc),
            fixedPrice: 9999999999999999999,
            maxPacksPerAddress: 10,
            requiresWhitelist: false,
            merkleRoot: bytes32(0),
            startTimestamp: block.timestamp - 1,
            expirationTimestamp: block.timestamp + 10 days,
            totalMintedPacks: 0,
            cancelled: false
        });

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

        uint256 mintConfigId = 0;
        // the target price
        int256 targetPrice = 100 * 1000000; // 100 USDC
        // price drops by 30% every day without sales
        int256 priceDecayPercent = 3e17;
        // we want to sell 2 packs per day
        int256 perTimeUnit = 2e18;

        cheats.deal(user1, 100 ether);

        // TEST: fixed price works
        cheats.startPrank(user1);
        usdc.getFaucet(1000000 * 1000); // 250 USDC
        uint256 price = minter.getPackPrice(mintConfigId);
        assertEq(price, mintConfig.fixedPrice);
        cheats.stopPrank();

        // TEST: check that fixed price is set to 0 after setting VRGDA
        minter.setVRGDAForMintConfig(mintConfigId, targetPrice, priceDecayPercent, perTimeUnit);
        (, , , , uint256 fixedPrice, , , , , , , ) = minter.getMintConfig(mintConfigId);
        assertEq(fixedPrice, 0);

        cheats.startPrank(user1, user1);

        uint256 price1 = minter.getPackPrice(mintConfigId);

        // TEST: after a mint event the price increases
        usdc.approve(address(executionDelegate), 1000000 * 1000000);
        minter.mint(mintConfigId, new bytes32[](0));
        uint256 price2 = minter.getPackPrice(mintConfigId);
        console.log("price2", price2);
        assert(price2 > price1);

        // TEST: if sales on time the price stays the same
        minter.mint{value: price2}(mintConfigId, new bytes32[](0));
        vm.warp(block.timestamp + 1 minutes);
        uint256 price3 = minter.getPackPrice(mintConfigId);
        assertEq(price1, price3);

        // TEST: the price stays consistent with values from yesterday
        minter.mint{value: price1}(mintConfigId, new bytes32[](0));
        uint256 price4 = minter.getPackPrice(mintConfigId);
        assertEq(price2, price4);

        minter.mint{value: price2}(mintConfigId, new bytes32[](0));

        // TEST: after a a minute without sales the price drops by priceDecayPercent
        vm.warp(block.timestamp + 2 minutes);
        uint256 price5 = minter.getPackPrice(mintConfigId);
        uint256 expectedPrice = (price1 * (1e18 - uint256(priceDecayPercent))) / 1e18;
        console.log("price5", price5);
        console.log("expectedPrice", expectedPrice);
        // max difference of 1 wei
        assertApproxEqAbs(expectedPrice, price5, 1);
        // rounds up
        assert(price5 >= expectedPrice);
        cheats.stopPrank();
    }
}
