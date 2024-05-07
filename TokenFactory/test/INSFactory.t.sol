// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {INSFactory} from "../src/INSFactory.sol";
import {INSToken} from "../src/INSToken.sol";

contract CounterTest is Test {
    INSFactory public factory;
    INSToken public token;

    address tom = makeAddr("tom");
    address bob = makeAddr("bob");

    function setUp() public {
        factory = new INSFactory();
    }

    function test_DeployInscription() public {
        vm.prank(tom);
        address tokenAddr = factory.deployInscription(
            "ABC",
            "ABC",
            1000000,
            100,
            1,
            bob
        );
        token = INSToken(tokenAddr);

        assertEq(factory.price(tokenAddr), 1);
        assertEq(factory.creator(tokenAddr), tom);
        assertEq(factory.project(tokenAddr), bob);
        assertEq(token.perMint(), 100);
        assertEq(token.topMint(), 1000000);
        assertEq(token.owner(), address(factory));
    }

    function test_MintInscription() public {
        vm.startPrank(tom);
        address tokenAddr = factory.deployInscription(
            "ABC",
            "ABC",
            1000000,
            100,
            1,
            bob
        );
        token = INSToken(tokenAddr);

        deal(bob, 1000 ether);

        vm.startPrank(bob);
        vm.expectRevert("exceed totalSupply");
        factory.mintInscription{value: 100000}(tokenAddr, 100000);

        vm.expectRevert("price error");
        factory.mintInscription{value: 10}(tokenAddr, 100);

        factory.mintInscription{value: 100}(tokenAddr, 100);
        assertEq(token.balanceOf(bob), 100 * 100);
    }
}
