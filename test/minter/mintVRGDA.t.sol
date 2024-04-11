pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";
import "../../src/interfaces/IMinter.sol";
// import "../../lib/forge-std/src/console.sol"; // leaving it commented out if needed
import {toTimeUnitWadUnsafe} from "../../src/VRGDA/wadMath.sol";

contract Mint is BaseTest {
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

    function test_mint_WETH_minute_time_unit_sanity_check() public {
        MintConfig memory mintConfig = MintConfig({
            collection: address(fantasyCards),
            cardsPerPack: 50,
            maxPacks: 100,
            paymentToken: address(weth),
            fixedPrice: 1,
            maxPacksPerAddress: 10,
            requiresWhitelist: false,
            merkleRoot: bytes32(0),
            startTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + 10 days,
            totalMintedPacks: 0,
            cancelled: false
        });

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

        uint256 mintConfigId = 0;
        // the target price
        int256 targetPrice = 1 ether;
        // price drops by 30% every minute without sales
        int256 priceDecayPercent = 3e17;
        // we want to sell 2 packs per minutes
        int256 perTimeUnit = 2e18;
        // the number of seconds in the time unit, 1 minute so 60
        int256 secondsPerTimeUnit = 60;

        // TEST: fixed price works
        cheats.startPrank(user1);
        weth.getFaucet(100 ether);
        weth.approve(address(executionDelegate), 100 ether);
        uint256 price = minter.getPackPrice(mintConfigId);
        assertEq(price, mintConfig.fixedPrice);
        cheats.stopPrank();

        // TEST: check that fixed price is set to 0 after setting VRGDA
        cheats.startPrank(mintConfigMaster);
        minter.setVRGDAForMintConfig(mintConfigId, targetPrice, priceDecayPercent, perTimeUnit, secondsPerTimeUnit);
        cheats.stopPrank();
        (, , , , uint256 fixedPrice, , , , , , , ) = minter.getMintConfig(mintConfigId);
        assertEq(fixedPrice, 0);

        cheats.startPrank(user1, user1);

        uint256 price1 = minter.getPackPrice(mintConfigId);

        // TEST: after a mint event the price increases
        minter.mint(mintConfigId, new bytes32[](0), price1);
        uint256 price2 = minter.getPackPrice(mintConfigId);
        assert(price2 > price1);

        // TEST: if sales on time the price stays the same
        minter.mint(mintConfigId, new bytes32[](0), price2);
        vm.warp(block.timestamp + 1 minutes);

        uint256 price3 = minter.getPackPrice(mintConfigId);
        assertEq(price1, price3);

        // TEST: the price stays consistent with values from 1 minute ago
        minter.mint(mintConfigId, new bytes32[](0), price1);
        uint256 price4 = minter.getPackPrice(mintConfigId);
        assertEq(price2, price4);

        minter.mint(mintConfigId, new bytes32[](0), price2);

        // TEST: after a minute without sales the price drops by priceDecayPercent
        vm.warp(block.timestamp + 2 minutes);
        uint256 price5 = minter.getPackPrice(mintConfigId);
        uint256 expectedPrice = (price1 * (1e18 - uint256(priceDecayPercent))) / 1e18;
        // max difference of 1 wei
        assertApproxEqAbs(expectedPrice, price5, 1);
        // rounds up
        assert(price5 > expectedPrice);
        cheats.stopPrank();
    }

    function test_mint_USDC_minute_time_unit_sanity_check() public {
        MintConfig memory mintConfig = MintConfig({
            collection: address(fantasyCards),
            cardsPerPack: 50,
            maxPacks: 100,
            paymentToken: address(usdc),
            fixedPrice: 9999999999999999999,
            maxPacksPerAddress: 10,
            requiresWhitelist: false,
            merkleRoot: bytes32(0),
            startTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + 10 days,
            totalMintedPacks: 0,
            cancelled: false
        });
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

        uint256 mintConfigId = 0;
        int256 targetPrice = 100 * 1e6; // 100 USDC
        // price drops by 30% every minute without sales
        int256 priceDecayPercent = 3e17;
        // we want to sell 2 packs per minute
        int256 perTimeUnit = 2e18;
        // the number of seconds in the time unit, 1 minute so 60
        int256 secondsPerTimeUnit = 60;

        // TEST: fixed price works
        cheats.startPrank(user1);
        usdc.getFaucet(1000 * 1e6); // 1000 USDC
        usdc.approve(address(executionDelegate), 1000 * 1e6);
        uint256 price = minter.getPackPrice(mintConfigId);
        assertEq(price, mintConfig.fixedPrice);
        cheats.stopPrank();

        cheats.startPrank(mintConfigMaster);
        // TEST: check that fixed price is set to 0 after setting VRGDA
        minter.setVRGDAForMintConfig(mintConfigId, targetPrice, priceDecayPercent, perTimeUnit, secondsPerTimeUnit);
        (, , , , uint256 fixedPrice, , , , , , , ) = minter.getMintConfig(mintConfigId);
        assertEq(fixedPrice, 0);
        cheats.stopPrank();

        cheats.startPrank(user1, user1);

        uint256 price1 = minter.getPackPrice(mintConfigId);

        // TEST: after a mint event the price increases
        minter.mint(mintConfigId, new bytes32[](0), price1);
        uint256 price2 = minter.getPackPrice(mintConfigId);
        assert(price2 > price1);

        // TEST: if sales on time the price stays the same
        minter.mint(mintConfigId, new bytes32[](0), price2);
        vm.warp(block.timestamp + 1 minutes);
        uint256 price3 = minter.getPackPrice(mintConfigId);
        assertEq(price1, price3);

        // TEST: the price stays consistent with values from 1 minute ago
        minter.mint(mintConfigId, new bytes32[](0), price1);
        uint256 price4 = minter.getPackPrice(mintConfigId);
        assertEq(price2, price4);

        minter.mint(mintConfigId, new bytes32[](0), price2);

        // TEST: after a a minute without sales the price drops by priceDecayPercent
        vm.warp(block.timestamp + 2 minutes);
        uint256 price5 = minter.getPackPrice(mintConfigId);
        uint256 expectedPrice = (price1 * (1e18 - uint256(priceDecayPercent))) / 1e18;
        assertApproxEqAbs(expectedPrice, price5, 1);
        assert(price5 >= expectedPrice);
        cheats.stopPrank();
    }

    function test_mint_WETH_hour_time_unit_target_price() public {
        MintConfig memory mintConfig = MintConfig({
            collection: address(fantasyCards),
            cardsPerPack: 50,
            maxPacks: 100,
            paymentToken: address(weth),
            fixedPrice: 1,
            maxPacksPerAddress: 10,
            requiresWhitelist: false,
            merkleRoot: bytes32(0),
            startTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + 10 days,
            totalMintedPacks: 0,
            cancelled: false
        });

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
        uint256 mintConfigId = 0;
        int256 targetPrice = 1 ether;
        int256 priceDecayPercent = 3e17;
        int256 perTimeUnit = 2e18;
        int256 secondsPerTimeUnit = 3600; // 1 hour
        cheats.startPrank(mintConfigMaster);
        minter.setVRGDAForMintConfig(mintConfigId, targetPrice, priceDecayPercent, perTimeUnit, secondsPerTimeUnit);
        cheats.stopPrank();
        cheats.warp(block.timestamp + uint256(secondsPerTimeUnit) / 2);
        uint256 price = minter.getPackPrice(mintConfigId);
        assertEq(price, uint256(targetPrice));
    }

    function test_mint_WETH_day_time_unit_target_price() public {
        MintConfig memory mintConfig = MintConfig({
            collection: address(fantasyCards),
            cardsPerPack: 50,
            maxPacks: 100,
            paymentToken: address(weth),
            fixedPrice: 1,
            maxPacksPerAddress: 10,
            requiresWhitelist: false,
            merkleRoot: bytes32(0),
            startTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + 10 days,
            totalMintedPacks: 0,
            cancelled: false
        });

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
        uint256 mintConfigId = 0;
        int256 targetPrice = 1 ether;
        int256 priceDecayPercent = 3e17;
        int256 perTimeUnit = 2e18;
        int256 secondsPerTimeUnit = 86400; // 1 hour
        cheats.startPrank(mintConfigMaster);
        minter.setVRGDAForMintConfig(mintConfigId, targetPrice, priceDecayPercent, perTimeUnit, secondsPerTimeUnit);
        cheats.stopPrank();
        cheats.warp(block.timestamp + 12 hours);
        uint256 price = minter.getPackPrice(mintConfigId);
        assertEq(price, uint256(targetPrice));
    }
}
