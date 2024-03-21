pragma solidity 0.8.20;

import "../../src/libraries/OrderLib.sol";

library HashLib {
    function getTypedDataHash(OrderLib.Order memory _order, bytes32 DOMAIN_SEPARATOR) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, OrderLib._hashOrder(_order)));
    }
}
