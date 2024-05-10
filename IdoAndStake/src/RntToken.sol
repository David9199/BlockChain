// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RntToken is ERC20 {
    constructor() ERC20("Rnt", "RNT") {
        _mint(address(msg.sender), 100000000 * 10 ** decimals());
    }
}
