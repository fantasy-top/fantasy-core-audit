pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract WhiteListCollection is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_WhiteListCollection() public {
        exchange.whiteListCollection(address(fantasyCards));
        assertEq(exchange.whitelistedCollections(address(fantasyCards)), true);
    }

    function test_unsuccessful_WhiteListCollection_caller_not_owner() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: proper error message
        exchange.whiteListCollection(address(fantasyCards));
        cheats.stopPrank();
    }
}
