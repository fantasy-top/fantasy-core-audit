pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetBaseURI is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_setBaseUri_with_admin() public {
        fantasyCards.setBaseURI("newBaseUri");
        assertEq(fantasyCards.baseURI(), "newBaseUri");
    }

    function test_unauthorised_setBaseUri() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: proper error message
        fantasyCards.setBaseURI("newBaseUri");
        cheats.stopPrank();
    }
}
