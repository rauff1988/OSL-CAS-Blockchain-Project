// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OSLToken is ERC20 {
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    constructor() ERC20("Open Source Lottery", "OSL") {
        _mint(msg.sender, MAX_SUPPLY);
    }
}
