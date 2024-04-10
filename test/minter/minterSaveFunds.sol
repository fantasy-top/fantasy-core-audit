pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";

contract Mint is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_mint_saveWETH() public {
        uint256 amount = 1 ether;

        cheats.startPrank(user1);
        weth.getFaucet(amount);
        weth.transfer(address(minter), amount);
        assertEq(weth.balanceOf(address(minter)), amount);
        cheats.stopPrank();

        minter.saveFunds(address(weth), user1, amount);
        assertEq(weth.balanceOf(address(minter)), 0);
    }

    function test_mint_saveETH() public {
        cheats.deal(address(minter), 1 ether);
        assertEq((address(minter)).balance, 1 ether);
        minter.saveFunds(address(0), user1, 1 ether);
        assertEq((address(minter)).balance, 0);
    }
}
