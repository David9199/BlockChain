// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Router02} from "../src/UniswapV2Router02.sol";
import {ERC20Token} from "../src/test/ERC20Token.sol";
import {UniswapV2ERC20} from "../src/UniswapV2ERC20.sol";
import {MyDex} from "../src/MyDex.sol";

contract MyDexTest is Test {
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    ERC20Token public WETH;
    ERC20Token public USDT;
    ERC20Token public RNT;
    MyDex public dex;

    address tom = makeAddr("tom");
    address bob = makeAddr("bob");
    address jim = makeAddr("jim");

    function setUp() public {
        vm.startPrank(tom);
        factory = new UniswapV2Factory(address(0));
        WETH = new ERC20Token("WETH", "WETH", 10000 * 10 ** 18);
        router = new UniswapV2Router02(address(factory), address(WETH));
        USDT = new ERC20Token("USDT", "USDT", 10000000 * 10 ** 18);
        RNT = new ERC20Token("RNT", "RNT", 10000000000 * 10 ** 18);
        dex = new MyDex(
            address(factory),
            address(WETH),
            address(router),
            address(USDT),
            address(RNT)
        );
        vm.stopPrank();
    }

    function test_addLiquidityMyDex() public {
        vm.startPrank(tom);
        WETH.approve(address(dex), 10 * 10 ** 18);
        USDT.approve(address(dex), 10000 * 10 ** 18);
        dex.addLiquidity(10000 * 10 ** 18, 10 * 10 ** 18);
        vm.stopPrank();

        address pair = factory.getPair(address(WETH), address(USDT));
        console.log("tom lp balance:", ERC20Token(pair).balanceOf(tom));
        console.log("pair WETH balance:", WETH.balanceOf(pair));
        console.log("pair USDT balance:", USDT.balanceOf(pair));
    }

    function test_sellETH() public {
        test_addLiquidityMyDex();

        vm.prank(tom);
        WETH.transfer(bob, 5*10**18);

        vm.startPrank(bob);
        WETH.approve(address(dex), 1*10**17);
        dex.sellETH(address(USDT), 1*10**17, 90 * 10 ** 18);
        vm.stopPrank();

        assertEq(USDT.balanceOf(bob) > 90 * 10 ** 18, true);
        address pair = factory.getPair(address(WETH), address(USDT));
        console.log("pair WETH balance:", WETH.balanceOf(pair));
        console.log("pair USDT balance:", USDT.balanceOf(pair));
    }

    function test_buyETH() public {
        test_addLiquidityMyDex();

        vm.prank(tom);
        USDT.transfer(bob, 100*10**18);

        vm.startPrank(bob);
        USDT.approve(address(dex), 10*10**18);
        dex.buyETH(address(USDT), 10*10**18, 0.009 ether);
        vm.stopPrank();

        assertEq(WETH.balanceOf(bob) > 0.009 ether, true);
        address pair = factory.getPair(address(WETH), address(USDT));
        console.log("pair WETH balance:", WETH.balanceOf(pair));
        console.log("pair USDT balance:", USDT.balanceOf(pair));
    }
}
