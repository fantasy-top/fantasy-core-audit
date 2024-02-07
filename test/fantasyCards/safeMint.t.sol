pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract TransferFrom is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_safeMint_with_executionDelegate() public {
        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();

        assertEq(fantasyCards.ownerOf(0), user1);
    }

    function test_unauthorised_safeMint() public {
        cheats.startPrank(user2);
        cheats.expectRevert();
        fantasyCards.safeMint(user1);
        cheats.stopPrank();
    }

    function test_safeMint_tokenCounter_increments() public {
        uint256 tokenCounterBeforeNewMint = fantasyCards.tokenCounter();

        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();

        assertEq(fantasyCards.tokenCounter(), tokenCounterBeforeNewMint + 1);
    }
}
