// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RntToken} from "../src/RntToken.sol";
import {TokenIdo} from "../src/TokenIdo.sol";

contract RntStakeTest is Test {
    RntToken public rnt;
    TokenIdo public ido;

    address tom = makeAddr("tom");
    address bob = makeAddr("bob");
    address jim = makeAddr("jim");

    function setUp() public {
        vm.startPrank(tom);
        rnt = new RntToken();
        ido = new TokenIdo();
        vm.stopPrank();
    }

    function test_Launch() public {
        vm.warp(block.timestamp + 1715342117);
        deal(tom, 1000 ether);
        deal(bob, 1000 ether);
        deal(jim, 1000 ether);

        vm.startPrank(tom);
        rnt.approve(address(ido), 1000000 * 10 ** 18);
        ido.launch{value: 1 ether}(
            address(rnt),
            block.timestamp + 1 days,
            block.timestamp + 5 days,
            1000000 * 10 ** 18,
            10 ether,
            15 ether,
            0.1 ether
        );
        assertEq(address(ido).balance, 1 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        vm.prank(bob);
        ido.presale{value: 5 ether}(address(rnt));
        assertEq(address(ido).balance, 6 ether);

        vm.startPrank(jim);
        ido.presale{value: 6 ether}(address(rnt));
        assertEq(address(ido).balance, 12 ether);
        ido.refund(address(rnt));
        vm.stopPrank();

        vm.prank(tom);
        ido.retrieve(address(rnt));
        assertEq(address(ido).balance, 1 ether);
    }
}
