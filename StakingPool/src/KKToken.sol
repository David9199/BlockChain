// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KKToken is ERC20 {
    constructor() ERC20("KKToken", "KK") {
        _mint(address(msg.sender), 10000000000 * 10 ** 18);
    }
}
