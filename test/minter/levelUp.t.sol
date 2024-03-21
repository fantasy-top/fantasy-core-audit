pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract LevelUp is BaseTest {
    function setUp() public override {
        super.setUp();

        cheats.startPrank(address(executionDelegate));
        for (uint256 i = 0; i < 5; i++) {
            fantasyCards.safeMint(user1);
        }
        cheats.stopPrank();
    }

    function test_successful_levelUp() public {
        uint256 cardsRequiredForLevelUp = minter.cardsRequiredForLevelUp();
        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i = 0; i < cardsRequiredForLevelUp; i++) {
            tokenIds[i] = i;
        }
        address collection = address(fantasyCards);

        cheats.startPrank(user1);
        minter.levelUp(tokenIds, collection);
        cheats.stopPrank();

        for (uint256 i = 0; i < cardsRequiredForLevelUp; i++) {
            cheats.expectRevert(); // TODO: proper revert message
            fantasyCards.ownerOf(i);
        }
        assertEq(fantasyCards.ownerOf(cardsRequiredForLevelUp), user1);
        assertEq(fantasyCards.tokenCounter(), cardsRequiredForLevelUp + 1);
    }

    function test_unsuccessful_levelUp_wrongCardNumber() public {
        uint256 cardsRequiredForLevelUp = minter.cardsRequiredForLevelUp();
        uint256[] memory tokenIds = new uint256[](cardsRequiredForLevelUp - 1);
        for (uint256 i = 0; i < cardsRequiredForLevelUp - 1; i++) {
            tokenIds[i] = i;
        }
        address collection = address(fantasyCards);

        cheats.startPrank(user1);
        cheats.expectRevert("wrong amount of cards to level up");
        minter.levelUp(tokenIds, collection);
        cheats.stopPrank();
    }

    function test_unsuccessful_levelUp_userNotOwner() public {
        uint256 cardsRequiredForLevelUp = minter.cardsRequiredForLevelUp();
        uint256[] memory tokenIds = new uint256[](cardsRequiredForLevelUp);
        for (uint256 i = 0; i < cardsRequiredForLevelUp; i++) {
            tokenIds[i] = i;
        }
        address collection = address(fantasyCards);

        cheats.startPrank(user2);
        cheats.expectRevert("caller does not own one of the tokens");
        minter.levelUp(tokenIds, collection);
        cheats.stopPrank();
    }
}
