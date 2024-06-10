pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract proxySafeTransferFrom is BaseTest {
    function setUp() public override {
        super.setUp();

        fantasyCardsProxy.approveIntegrator(user1);
        fantasyCardsProxy.approveIntegrator(user2);
    }

    function test_successful_safeTransferFromWithApprove() public {
        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();

        cheats.startPrank(address(user1));
        fantasyCardsProxy.approve(user2, 0);
        fantasyCards.approve(address(executionDelegate), 0);
        fantasyCardsProxy.safeTransferFrom(user1, user2, 0);
        cheats.stopPrank();
        assertEq(fantasyCards.ownerOf(0), user2);
    }

    function test_successful_safeTransferFromWithSetApprovalForAll() public {
        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();

        cheats.startPrank(address(user1));
        fantasyCardsProxy.setApprovalForAll(user2, true);
        fantasyCards.approve(address(executionDelegate), 0);
        fantasyCardsProxy.safeTransferFrom(user1, user2, 0);
        cheats.stopPrank();
        assertEq(fantasyCards.ownerOf(0), user2);
    }

    function test_unauthorised_safeTransferFrom() public {
        cheats.startPrank(user2);
        cheats.expectRevert(); // REVIEW: proper revert message?
        fantasyCardsProxy.transferFrom(user1, user2, 0);
        cheats.stopPrank();
    }
}
