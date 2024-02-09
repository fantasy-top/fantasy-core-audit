pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetExecutionDelegate is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_setExecutionDelegate() public {
        minter.setExecutionDelegate(address(0x12345));
        assertEq(address(minter.executionDelegate()), address(0x12345));
    }

    function test_unsuccessful_setExecutionDelegate_address_zero() public {
        cheats.expectRevert("Execution delegate address cannot be 0x0");
        minter.setExecutionDelegate(address(0));
    }

    function test_unauthorized_setExecutionDelegate_not_owner() public {
        cheats.startPrank(user1);
        cheats.expectRevert(); // REVIEW: proper error message?
        minter.setExecutionDelegate(user1);
        cheats.stopPrank();
    }
}