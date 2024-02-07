pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";
import "../../src/libraries/OrderLib.sol";

contract CancelOrder is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_successful_cancelOrder() public {
        // Create order
        OrderLib.Order memory order = OrderLib.Order(
            user1,
            OrderLib.Side.Sell,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            bytes32(0),
            0
        );
        bytes32 orderHash = OrderLib._hashOrder(order);

        // cancel order
        cheats.startPrank(user1);
        exchange.cancelOrder(order);
        cheats.stopPrank();

        assertEq(exchange.cancelledOrFilled(orderHash), true);
    }

    function test_unsuccessful_cancelOrder_wrong_trader() public {
        // Create order
        OrderLib.Order memory order = OrderLib.Order(
            user2,
            OrderLib.Side.Sell,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            bytes32(0),
            0
        );

        // cancel order
        cheats.startPrank(user1);
        cheats.expectRevert("msg.sender is not the trader");
        exchange.cancelOrder(order);
        cheats.stopPrank();
    }
}
