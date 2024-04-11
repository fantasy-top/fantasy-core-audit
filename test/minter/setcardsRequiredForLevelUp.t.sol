pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetcardsRequiredForLevelUp is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_setcardsRequiredForLevelUp() public {
        cheats.startPrank(mintConfigMaster);
        minter.setcardsRequiredForLevelUp(123);
        cheats.stopPrank();

        assertEq(minter.cardsRequiredForLevelUp(), 123);
    }

    function test_unsuccessful_setcardsRequiredForLevelUp_notOwner() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: real error message
        minter.setcardsRequiredForLevelUp(123);
        cheats.stopPrank();
    }
}
