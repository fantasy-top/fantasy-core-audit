pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetExecutionDelegate is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_setExecutionDelegate() public {
        address executionDelegate = address(0x123);
        exchange.setExecutionDelegate(executionDelegate);

        assertEq(address(exchange.executionDelegate()), executionDelegate);
    }

    function test_unsuccessful_setExecutionDelegate_not_owner() public {
        address executionDelegate = address(0x123);
        cheats.startPrank(user1);
        cheats.expectRevert();
        exchange.setExecutionDelegate(executionDelegate);
        cheats.stopPrank();
    }

    function test_unsuccessful_setExecutionDelegate_zero_address() public {
        address executionDelegate = address(0);
        cheats.expectRevert("excution delegate can't be address 0");
        exchange.setExecutionDelegate(executionDelegate);
    }
}