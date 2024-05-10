// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RntToken} from "../src/RntToken.sol";
import {esRntToken} from "../src/esRntToken.sol";
import {RntStake} from "../src/RntStake5.sol";

contract RntStakeTest is Test {
    RntToken public rnt;
    esRntToken public esRnt;
    RntStake public stake;

    address tom = makeAddr("tom");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.startPrank(tom);
        rnt = new RntToken();
        esRnt = new esRntToken();
        stake = new RntStake(address(rnt), address(esRnt));
        esRnt.setRntToken(address(rnt));
        esRnt.setRntStake(address(stake));
        vm.stopPrank();
    }

    function test_Stake() public {
        vm.warp(block.timestamp + 1715342117);
        vm.startPrank(tom);
        rnt.transfer(address(stake), 10000);
        rnt.transfer(bob, 300);
        vm.startPrank(bob);
        rnt.approve(address(stake), 300);
        stake.stake(100);
        vm.warp(block.timestamp + 2 days);
        stake.stake(200);
        assertEq(rnt.balanceOf(address(stake)), 10300);

        (uint256 rntAmount, uint256 unDrawEsRnt, uint64 lastSettleTime) = stake
            .stakes(bob);
        assertEq(rntAmount, 300);
        assertEq(unDrawEsRnt, 200);
        assertEq(lastSettleTime, block.timestamp / 1 days);

        vm.warp(block.timestamp + 3 days);
        stake.drawEsRnt();
        // stake.retrieveRnt();
        assertEq(esRnt.balanceOf(bob), 1100);
        assertEq(stake.lastReleaseDate(bob), block.timestamp / 1 days);
        assertEq(stake.esRntLocks(bob, stake.lastReleaseDate(bob)), 1100);

        vm.warp(block.timestamp + 5 days);
        stake.drawEsRnt();
        assertEq(esRnt.balanceOf(bob), 2600);
        assertEq(stake.esRntLocks(bob, uint32(block.timestamp / 1 days)), 1500);

        // vm.warp(block.timestamp + 30 days);
        // esRnt.approve(address(stake), 500);
        // stake.rntRelease(500);
        // assertEq(esRnt.balanceOf(bob), 600);
        // assertEq(rnt.balanceOf(bob), 500);

        vm.warp(block.timestamp + 10 days);
        esRnt.approve(address(stake), 10000);
        stake.rntRelease(100);
        assertEq(esRnt.balanceOf(bob), 1500);
        assertEq(rnt.balanceOf(bob), 550);
    }
}
