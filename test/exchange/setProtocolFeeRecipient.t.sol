pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetProtocolFeeRecipient is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_setProtocolFeeRecipient() public {
        address protocolFeeRecipient = address(0x123);
        exchange.setProtocolFeeRecipient(protocolFeeRecipient);

        assertEq(exchange.protocolFeeRecipient(), protocolFeeRecipient);
    }

    function test_unsuccessful_setProtocolFeeRecipient_not_owner() public {
        address protocolFeeRecipient = address(0x123);
        cheats.startPrank(user1);
        cheats.expectRevert();
        exchange.setProtocolFeeRecipient(protocolFeeRecipient);
        cheats.stopPrank();
    }

    function test_unsuccessful_setProtocolFeeRecipient_zero_address() public {
        address protocolFeeRecipient = address(0);
        cheats.expectRevert("protocol fee recipient can't be address 0");
        exchange.setProtocolFeeRecipient(protocolFeeRecipient);
    }
}
