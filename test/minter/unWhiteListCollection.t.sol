pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract UnWhiteListCollection is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_unWhiteListCollection() public {
        minter.whiteListCollection(address(fantasyCards));

        minter.unWhiteListCollection(address(fantasyCards));
        assertEq(minter.whitelistedCollections(address(fantasyCards)), false);
    }

    function test_unsuccessful_unWhiteListCollection_caller_not_owner() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: proper error message
        minter.unWhiteListCollection(address(fantasyCards));
        cheats.stopPrank();
    }
}
