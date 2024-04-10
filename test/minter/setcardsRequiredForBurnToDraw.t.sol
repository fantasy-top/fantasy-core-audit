pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetcardsRequiredForBurnToDraw is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_setcardsRequiredForBurnToDraw() public {
        minter.setcardsRequiredForBurnToDraw(123);

        assertEq(minter.cardsRequiredForBurnToDraw(), 123);
    }

    function test_unsuccessful_setcardsRequiredForBurnToDraw_notOwner() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: real error message
        minter.setcardsRequiredForBurnToDraw(123);
        cheats.stopPrank();
    }
}
