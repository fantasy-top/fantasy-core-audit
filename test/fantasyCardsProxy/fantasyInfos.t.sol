pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract fantasyInfos is BaseTest {
    function setUp() public override {
        super.setUp();

        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();
    }

    function test_successful_balanceOf() public {
        assertEq(fantasyCardsProxy.balanceOf(user1), 1);
    }

    function test_successful_ownerOf() public {
        assertEq(fantasyCardsProxy.ownerOf(0), user1);
    }

    function test_successful_name() public {
        assertEq(fantasyCardsProxy.name(), "Fantasy");
    }

    function test_successful_symbol() public {
        assertEq(fantasyCardsProxy.symbol(), "FANTASY");
    }

    function test_successful_tokenURI() public {
        assertEq(fantasyCardsProxy.tokenURI(0), "https://fantasy-top-cards.s3.eu-north-1.amazonaws.com/0");
    }

    function test_unsuccessful_tokenURI() public {
        cheats.expectRevert(); // REVIEW: proper revert message?
        fantasyCardsProxy.tokenURI(1);
        cheats.stopPrank();
    }
}
