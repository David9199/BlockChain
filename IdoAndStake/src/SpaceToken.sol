// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceToken is ERC20 {
    constructor() ERC20("Space", "SPACE") {
        _mint(address(msg.sender), 10000000 * 10 ** decimals());
    }
}
