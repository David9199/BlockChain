// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Staking} from "../src/Staking3.sol";
import {KKToken} from "../src/KKToken.sol";

contract StakingTest is Test {
    KKToken public kk;
    Staking public stake;

    address tom = makeAddr("tom");
    address bob = makeAddr("bob");
    address jim = makeAddr("jim");

    function setUp() public {
        vm.startPrank(tom);
        kk = new KKToken();
        stake = new Staking(address(kk));
        kk.transfer(address(stake), 100000 * 10 ** 18);
        vm.stopPrank();

        deal(tom, 100 ether);
        deal(bob, 100 ether);
        deal(jim, 100 ether);
    }

    function test_stake() public {
        vm.roll(10);

        vm.startPrank(bob);
        stake.stake{value: 1 ether}();

        vm.stopPrank();

        assertEq(stake.balanceOf(bob), 1 ether);
        assertEq(stake.totalStakeEth(), address(stake).balance);
        console.log("lastBlock:", stake.lastBlock());
        console.log(
            "accumulatedInterestRate:",
            stake.accumulatedInterestRate()
        );

        vm.roll(20);

        vm.startPrank(jim);
        stake.stake{value: 1 ether}();

        vm.stopPrank();

        vm.roll(30);

        assertEq(stake.balanceOf(jim), 1 ether);
        assertEq(stake.totalStakeEth(), address(stake).balance);

        console.log("totalStakeEth:", stake.totalStakeEth());
        console.log("lastBlock:", stake.lastBlock());
        console.log("accumulatedRate:", stake.accumulatedRate());
        console.log(
            "accumulatedInterestRate:",
            stake.accumulatedInterestRate()
        );
    }

    function test_claim() public {
        test_stake();

        vm.roll(40);
        vm.startPrank(bob);
        uint256 unDrawKKAmount = stake.earned(bob);
        stake.claim();
        vm.stopPrank();

        vm.startPrank(jim);
        uint256 unDrawKKAmount2 = stake.earned(jim);
        stake.claim();
        vm.stopPrank();

        assertEq(kk.balanceOf(bob), unDrawKKAmount);
        assertEq(kk.balanceOf(jim), unDrawKKAmount2);

        console.log("unDrawKKAmount:", unDrawKKAmount);
        console.log("unDrawKKAmount2:", unDrawKKAmount2);
        console.log("lastBlock:", stake.lastBlock());
        console.log("totalStakeEth:", stake.totalStakeEth());
        console.log("accumulatedRate:", stake.accumulatedRate());
        console.log(
            "accumulatedInterestRate:",
            stake.accumulatedInterestRate()
        );
    }

    function test_unstake() public {
        test_stake();

        vm.roll(40);
        vm.startPrank(bob);
        uint256 unDrawKKAmount = stake.earned(bob);
        stake.unstake();
        vm.stopPrank();

        assertEq(stake.balanceOf(bob), 0);
        assertEq(bob.balance, 100 ether);
        assertEq(kk.balanceOf(bob), unDrawKKAmount);

        console.log("totalStakeEth:", stake.totalStakeEth());
        console.log("lastBlock:", stake.lastBlock());
        console.log(
            "accumulatedInterestRate:",
            stake.accumulatedInterestRate()
        );
    }
}
