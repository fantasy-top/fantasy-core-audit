pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SetProtocolFeeBps is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_setProtocolFeeBps() public {
        uint256 protocolFeeBps = 12;
        exchange.setProtocolFeeBps(protocolFeeBps);

        assertEq(exchange.protocolFeeBps(), protocolFeeBps);
    }

    function test_unsuccessful_setProtocolFeeBps_not_owner() public {
        uint256 protocolFeeBps = 12;
        cheats.startPrank(user1);
        cheats.expectRevert();
        exchange.setProtocolFeeBps(protocolFeeBps);
        cheats.stopPrank();
    }

    function test_unsuccessful_setProtocolFeeBps_over_max() public {
        uint256 protocolFeeBps = exchange.INVERSE_BASIS_POINT() + 1;
        cheats.expectRevert("protocol fee above 100%");
        exchange.setProtocolFeeBps(protocolFeeBps);
    }
}
