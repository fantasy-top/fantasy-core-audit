pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";
import "../../src/libraries/OrderLib.sol";
import "../helpers/HashLib.sol";
import "../helpers/TraderContract.sol";

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

    function test_successful_sell_WETH() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
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
        assertEq(weth.balanceOf(user1), 1 ether - weth.balanceOf(treasury));
        assertEq(fantasyCards.ownerOf(0), user2);
        assertEq(fantasyCards.balanceOf(user1), 0);
    }

    function test_unsuccessful_sell_ETH() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(0),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        cheats.startPrank(user1, user1);
        cheats.expectRevert("payment token can not be ETH for buy order");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_collection_not_whitelisted() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(1),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        cheats.startPrank(user1, user1);
        cheats.expectRevert("Collection is not whitelisted");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_paymentToken_not_whitelisted() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(1),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        cheats.deal(user2, 1 ether);

        // Execute buy
        cheats.startPrank(user1, user1);
        cheats.expectRevert("Invalid payment token");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_invalid_order_side() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Sell,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        // Execute buy
        cheats.startPrank(user1, user1);
        cheats.expectRevert("order must be a buy");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_expired_order() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            0,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        // Execute buy
        cheats.startPrank(user1, user1);
        cheats.expectRevert("order expired");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_invalid_trader() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            address(0),
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        // Execute buy
        cheats.startPrank(user1, user1);
        cheats.expectRevert("order trader is 0");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_canceled_order() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance and Cancel order
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        exchange.cancelOrder(buyOrder);
        cheats.stopPrank();

        // Execute buy
        cheats.startPrank(user1, user1);
        cheats.expectRevert("buy order cancelled or filled");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_filled_order() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance and Cancel order
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        // Execute buy twice
        cheats.startPrank(user1, user1);
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.expectRevert("buy order cancelled or filled");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_invalid_signature() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        // sign with user1 private key
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user1PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance and Cancel order
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        // Execute buy twice
        cheats.startPrank(user1, user1);
        cheats.expectRevert("invalid signature");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_invalid_merkle_proof() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        // Corrupt merkle proof
        merkleProof[0] = 0x00000;

        // Execute buy
        cheats.startPrank(user1, user1);
        cheats.expectRevert("invalid tokenId");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_invalid_token_id() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        // Execute buy but the token id does not match the merkle proof
        cheats.startPrank(user1, user1);
        cheats.expectRevert("invalid tokenId");
        exchange.sell(buyOrder, buyerSignature, 1, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_seller_does_not_have_the_token() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        // transfer the token from user1 to user2, so user1 does not have the token
        cheats.startPrank(address(executionDelegate));
        fantasyCards.transferFrom(user1, user2, 0);
        cheats.stopPrank();

        cheats.startPrank(user1, user1);
        cheats.expectRevert();
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_buyer_does_not_have_the_funds() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // Execute buy
        cheats.startPrank(user1, user1);
        cheats.expectRevert();
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_not_EOA() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // DEPLOY TRADER CONTRACT
        TraderContract traderContract = new TraderContract(address(exchange), address(minter));

        // Execute buy
        cheats.startPrank(user1, user1);
        cheats.expectRevert("Function can only be called by an EOA");
        traderContract.sellOnExchange(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }

    function test_unsuccessful_sell_price_bellow_minimumPrice() public {
        // Create order
        OrderLib.Order memory buyOrder = OrderLib.Order(
            user2,
            OrderLib.Side.Buy,
            address(fantasyCards),
            0,
            address(weth),
            1 ether,
            999999999999999999999,
            merkleRoot,
            10_001
        );

        // Sign order
        bytes32 orderHash = HashLib.getTypedDataHash(buyOrder, exchange.domainSeparator());
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(user2PrivateKey, orderHash);
        bytes memory buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        exchange.setMinimumPricePerPaymentToken(address(weth), buyOrder.price + 1);

        // Give WETH allowance
        cheats.startPrank(user2);
        weth.getFaucet(1 ether);
        weth.approve(address(executionDelegate), 1 ether);
        cheats.stopPrank();

        cheats.startPrank(user1, user1);
        cheats.expectRevert("price bellow minimumPrice");
        exchange.sell(buyOrder, buyerSignature, 0, merkleProof);
        cheats.stopPrank();
    }
}
