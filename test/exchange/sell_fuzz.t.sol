pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";
import "../../src/libraries/OrderLib.sol";
import "../helpers/HashLib.sol";

contract Sell is BaseTest {
    bytes32 merkleRoot;
    bytes32[] merkleProof = new bytes32[](2); // Merkle proof for id 0 address

    function setUp() public override {
        super.setUp();

        merkleRoot = 0x2c24f92f65cdd0fde0264c1f41fadf17cb35cdffeaca769e5673e72b072be707; // Merkle root for ids 0 , 1, 2 and 3
        merkleProof[0] = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;
        merkleProof[1] = 0xc5fd106a8e5214837c622e5fdef112b1d83ad6de66beafb53451c77843c9d04e;

        cheats.startPrank(address(executionDelegate));
        fantasyCards.safeMint(user1);
        cheats.stopPrank();

        cheats.startPrank(user1);
        fantasyCards.approve(address(executionDelegate), 0);
        cheats.stopPrank();
    }

    function test_successful_sell_WETH_fuzz(uint256 _price) public {
        if (_price > 120000000 ether) return;

        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            _price,
            999999999999999999999,
            merkleRoot,
            100_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(buyOrder.price);
        weth.approve(address(executionDelegate), buyOrder.price);
        cheats.stopPrank();

        // Execute buy
        cheats.startPrank(user1, user1);
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();

        // Check balances
        assertEq(
            weth.balanceOf(treasury),
            (buyOrder.price * exchange.protocolFeeBps()) / exchange.INVERSE_BASIS_POINT()
        );
        assertEq(weth.balanceOf(user1), buyOrder.price - weth.balanceOf(treasury));
        assertEq(fantasyCards.ownerOf(0), user2);
        assertEq(fantasyCards.balanceOf(user1), 0);
    }
}
