pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract NewMintConfig is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_newMintConfig() public {
        // Act
        minter.newMintConfig(
            address(0x1),
            10,
            100,
            address(0x2),
            100,
            true,
            true,
            0x3000000000000000000000000000000000000000000000000000000000000000,
            300
        );

        // Assert
        (
            address actualCollection,
            uint256 actualCardsPerPack,
            uint256 actualTotalPacks,
            address actualPaymentToken,
            uint256 actualPrice,
            bool actualOnePerAddress,
            bool actualRequiresWhitelist,
            bytes32 actualMerkleRoot,
            uint256 actualExpirationTimestamp,
            uint256 actualTotalMintedPacks,
            bool actualCancelled
        ) = minter.getMintConfig(0);

        assertEq(actualCollection, address(0x1));
        assertEq(actualCardsPerPack, 10);
        assertEq(actualTotalPacks, 100);
        assertEq(actualPaymentToken, address(0x2));
        assertEq(actualPrice, 100);
        assertEq(actualOnePerAddress, true);
        assertEq(actualRequiresWhitelist, true);
        assertEq(
            actualMerkleRoot,
            0x3000000000000000000000000000000000000000000000000000000000000000
        );
        assertEq(actualExpirationTimestamp, 300);
        assertEq(actualTotalMintedPacks, 0);
        assertEq(actualCancelled, false);
    }

    function test_mintConfigIdCounter() public {
        // Arrange
        address collection = address(0x1);
        uint256 cardsPerPack = 10;
        uint256 totalPacks = 100;
        address paymentToken = address(0x2);
        uint256 price = 100;
        bool onePerAddress = true;
        bool requiresWhitelist = true;
        bytes32 merkleRoot = 0x3000000000000000000000000000000000000000000000000000000000000000;
        uint256 expirationTimestamp = 300;

        // Act
        minter.newMintConfig(
            collection,
            cardsPerPack,
            totalPacks,
            paymentToken,
            price,
            onePerAddress,
            requiresWhitelist,
            merkleRoot,
            expirationTimestamp
        );

        // Assert
        assertEq(minter.mintConfigIdCounter(), 1);
    }

    function test_unauthorized_newMintConfig() public {
        // Arrange
        address collection = address(0x1);
        uint256 cardsPerPack = 10;
        uint256 totalPacks = 100;
        address paymentToken = address(0x2);
        uint256 price = 100;
        bool onePerAddress = true;
        bool requiresWhitelist = true;
        bytes32 merkleRoot = 0x3000000000000000000000000000000000000000000000000000000000000000;
        uint256 expirationTimestamp = 300;

        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: proper error message?
        minter.newMintConfig(
            collection,
            cardsPerPack,
            totalPacks,
            paymentToken,
            price,
            onePerAddress,
            requiresWhitelist,
            merkleRoot,
            expirationTimestamp
        );
        cheats.stopPrank();
    }
}
