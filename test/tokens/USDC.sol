// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("Test USDC", "t.USDC") {}

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function getFaucet(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
