pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract TransferFrom is BaseTest {
    function setUp() public override {
        super.setUp();

        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();

        cheats.startPrank(user1);
        fantasyCards.approve(user2, 0);
        fantasyCards.approve(address(executionDelegate), 0);
        cheats.stopPrank();
    }

    function test_successful_transferFrom_with_executionDelegate() public {
        cheats.startPrank(address(executionDelegate));
        fantasyCards.transferFrom(user1, user2, 0);
        cheats.stopPrank();
        assertEq(fantasyCards.ownerOf(0), user2);
    }

    function test_unauthorised_transferFrom() public {
        cheats.startPrank(user2);
        cheats.expectRevert();
        fantasyCards.transferFrom(user1, user2, 0);
        cheats.stopPrank();
    }
}
