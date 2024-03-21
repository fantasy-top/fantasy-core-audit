pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract Burn is BaseTest {
    function setUp() public override {
        super.setUp();

        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();
    }

    function test_successful_burn() public {
        cheats.startPrank(address(executionDelegate));
        fantasyCards.burn(0);
        cheats.stopPrank();

        assertEq(fantasyCards.balanceOf(user1), 0);
        assertEq(fantasyCards.tokenCounter(), 1);
    }

    function test_unauthorised_burn() public {
        cheats.startPrank(user2);
        cheats.expectRevert();
        fantasyCards.burn(0);
        cheats.stopPrank();
    }
}
