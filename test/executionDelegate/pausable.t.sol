pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract Pausable is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_pause() public {
        cheats.startPrank(pauserAndCanceler);
        executionDelegate.pause();
        cheats.stopPrank();

        assertTrue(executionDelegate.paused());
    }

    function test_unSuccessful_pause_not_owner() public {
        cheats.expectRevert();
        executionDelegate.pause();
    }

    function test_successful_unpause() public {
        cheats.startPrank(pauserAndCanceler);
        executionDelegate.pause();
        cheats.stopPrank();

        executionDelegate.unpause();

        assertFalse(executionDelegate.paused());
    }

    function test_unSuccessful_unPause_not_owner() public {
        cheats.startPrank(pauserAndCanceler);
        executionDelegate.pause();
        cheats.stopPrank();

        cheats.startPrank(user1);
        cheats.expectRevert();
        executionDelegate.unpause();
        cheats.stopPrank();
    }

    function test_functions_blocked_when_paused() public {
        cheats.startPrank(pauserAndCanceler);
        executionDelegate.pause();
        cheats.stopPrank();

        cheats.expectRevert(bytes4(keccak256("EnforcedPause()")));
        executionDelegate.mintFantasyCard(address(fantasyCards), user1);

        cheats.expectRevert(bytes4(keccak256("EnforcedPause()")));
        executionDelegate.transferERC721Unsafe(address(fantasyCards), user1, user2, 1);

        cheats.expectRevert(bytes4(keccak256("EnforcedPause()")));
        executionDelegate.transferERC721(address(fantasyCards), user1, user2, 1);

        cheats.expectRevert(bytes4(keccak256("EnforcedPause()")));
        executionDelegate.transferERC1155(address(fantasyCards), user1, user2, 1, 1);

        cheats.expectRevert(bytes4(keccak256("EnforcedPause()")));
        executionDelegate.transferERC20(address(fantasyCards), user1, user2, 1);
    }
}
