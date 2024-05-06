// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20Permit {
    // using Address for address;

    constructor() ERC20("MyToken", "MT") ERC20Permit("MyToken") {
        // _mint(msg.sender, 100000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

}