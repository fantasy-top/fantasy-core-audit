pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract LevelUp is BaseTest {
    function setUp() public override {
        super.setUp();
        cheats.startPrank(address(executionDelegate));
        for (uint256 i = 0; i < 15; i++) {
            fantasyCards.safeMint(user1);
        }
        cheats.stopPrank();
    }

    function test_successful_burnToDraw() public {
        uint256 cardsRequiredForBurnToDraw = minter.cardsRequiredForBurnToDraw();
        uint256[] memory tokenIds = new uint256[](15);
        for (uint256 i = 0; i < cardsRequiredForBurnToDraw; i++) {
            tokenIds[i] = i;
        }
        address collection = address(fantasyCards);
        cheats.startPrank(user1);
        minter.burnToDraw(tokenIds, collection);
        cheats.stopPrank();
        for (uint256 i = 0; i < cardsRequiredForBurnToDraw; i++) {
            cheats.expectRevert(); // TODO: proper revert message
            fantasyCards.ownerOf(i);
        }
        assertEq(fantasyCards.ownerOf(cardsRequiredForBurnToDraw), user1);
        assertEq(fantasyCards.tokenCounter(), cardsRequiredForBurnToDraw + 1);
    }

    function test_unsuccessful_burnToDraw_wrongCardNumber() public {
        uint256 cardsRequiredForBurnToDraw = minter.cardsRequiredForBurnToDraw();
        uint256[] memory tokenIds = new uint256[](cardsRequiredForBurnToDraw - 1);
        for (uint256 i = 0; i < cardsRequiredForLevelUp - 1; i++) {
            tokenIds[i] = i;
        }
        address collection = address(fantasyCards);
        cheats.startPrank(user1);
        cheats.expectRevert("wrong amount of cards to draw new cards");
        minter.burnToDraw(tokenIds, collection);
        cheats.stopPrank();
    }

    function test_unsuccessful_levelUp_userNotOwner() public {
        uint256 cardsRequiredForBurnToDraw = minter.cardsRequiredForBurnToDraw();
        uint256[] memory tokenIds = new uint256[](cardsRequiredForBurnToDraw);
        for (uint256 i = 0; i < cardsRequiredForLevelUp; i++) {
            tokenIds[i] = i;
        }
        address collection = address(fantasyCards);
        cheats.startPrank(user2);
        cheats.expectRevert("caller does not own one of the tokens");
        minter.burnToDraw(tokenIds, collection);
        cheats.stopPrank();
    }
}
