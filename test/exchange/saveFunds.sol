pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract SaveFunds is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_exchange_save_ERC20() public {
        uint256 amount = 1 ether;

        cheats.startPrank(user1);
        weth.getFaucet(amount);
        weth.transfer(address(exchange), amount);
        assertEq(weth.balanceOf(address(exchange)), amount);
        cheats.stopPrank();

        exchange.saveFunds(address(weth), user1, amount);
        assertEq(weth.balanceOf(address(exchange)), 0);
        assertEq(weth.balanceOf(user1), 1 ether);
    }

    function test_exchange_save_ETH() public {
        cheats.deal(address(exchange), 1 ether);
        assertEq((address(exchange)).balance, 1 ether);
        exchange.saveFunds(address(0), user1, 1 ether);
        assertEq((address(exchange)).balance, 0);
        assertEq(user1.balance, 1 ether);
    }
}
