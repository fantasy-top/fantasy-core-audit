pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract proxyTransferFrom is BaseTest {
    function setUp() public override {
        super.setUp();

        fantasyCardsProxy.approveIntegrator(user1);
        fantasyCardsProxy.approveIntegrator(user2);
    }

    function test_successful_transferFromWithApprove() public {
        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();

        cheats.startPrank(address(user1));
        fantasyCardsProxy.approve(user2, 0);
        fantasyCards.approve(address(executionDelegate), 0);
        fantasyCardsProxy.transferFrom(user1, user2, 0);
        cheats.stopPrank();
        assertEq(fantasyCards.ownerOf(0), user2);
        // assertEq(fantasyCardsProxy.ownerOf(0), user2);
    }

    function test_successful_transferFromWithSetApprovalForAll() public {
        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();

        cheats.startPrank(address(user1));
        fantasyCardsProxy.setApprovalForAll(user2, true);
        fantasyCards.approve(address(executionDelegate), 0);
        fantasyCardsProxy.transferFrom(user1, user2, 0);
        cheats.stopPrank();
        assertEq(fantasyCards.ownerOf(0), user2);
        // assertEq(fantasyCardsProxy.ownerOf(0), user2);
    }

    function test_unauthorised_transferFrom() public {
        cheats.startPrank(user2);
        cheats.expectRevert(); // REVIEW: proper revert message?
        fantasyCardsProxy.transferFrom(user1, user2, 0);
        cheats.stopPrank();
    }
}
