// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Router02} from "../src/UniswapV2Router02.sol";
import {ERC20Token} from "../src/test/ERC20Token.sol";
import {UniswapV2ERC20} from "../src/UniswapV2ERC20.sol";

contract UniswapV2RouterTest is Test {
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    ERC20Token public WETH;
    ERC20Token public USDT;
    ERC20Token public RNT;

    address feeto = makeAddr("feeto");
    address tom = makeAddr("tom");
    address bob = makeAddr("bob");
    address jim = makeAddr("jim");


    function setUp() public {
        vm.startPrank(tom);
        factory = new UniswapV2Factory(address(0));
        WETH = new ERC20Token("WETH","WETH",10000*10**18);
        router = new UniswapV2Router02(address(factory),address(WETH));
        USDT = new ERC20Token("USDT","USDT",10000000*10**18);
        RNT = new ERC20Token("RNT","RNT",10000000000*10**18);
        vm.stopPrank();
    }

    function test_createPair() public {
        address pair = factory.createPair(address(WETH), address(USDT));
        console.log(pair);
    }

    function test_addLiquidityETH() public {
        address pair = factory.createPair(address(RNT), address(WETH));
        console.log("pair:",pair);

        vm.startPrank(tom);
        WETH.approve(address(router), 1000*10**18);
        RNT.approve(address(router), 1000000*10**18);
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidity(
            address(RNT),
            address(WETH),
            1000000*10**18,
            10*10**18,
            0,
            0,
            jim,
            block.timestamp
        );
        vm.stopPrank();

        console.log("amountToken:",amountToken,"amountETH:",amountETH);
        console.log("totalSupply:",UniswapV2ERC20(pair).totalSupply());
        address pair2 = factory.getPair(address(WETH), address(RNT));
        assertEq(pair2, pair);
        assertEq(UniswapV2ERC20(pair).balanceOf(jim), liquidity);
    }

    function test_swap() public {
        test_addLiquidityETH();

        vm.prank(tom);
        WETH.transfer(bob, 5*10**18);

        vm.startPrank(bob);
        WETH.approve(address(router), 1000*10**18);
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(RNT);
        uint[] memory amounts = router.swapExactTokensForTokens(1*10**18, 0, path, bob, block.timestamp);
        console.log("amounts:",amounts[0]);
        // router.swapExactTokensForTokensSupportingFeeOnTransferTokens(1*10**18, 0, path, bob, block.timestamp);

        RNT.approve(address(router), 1000*10**18);
        path[0] = address(RNT);
        path[1] = address(WETH);
        amounts = router.swapExactTokensForTokens(5*10**18, 0, path, bob, block.timestamp);
        console.log("amounts:",amounts[0]); 
        vm.stopPrank();
    }

    function test_removeLiquidity() public {
        test_addLiquidityETH();

        vm.startPrank(jim);
        address pair = factory.getPair(address(WETH), address(RNT));
        uint liquidity = UniswapV2ERC20(pair).balanceOf(jim);
        UniswapV2ERC20(pair).approve(address(router), liquidity);
        (uint amountA, uint amountB) = router.removeLiquidity(address(WETH), 
        address(RNT), liquidity, 0, 0, jim, block.timestamp);
        vm.stopPrank();

        console.log("amountA:",amountA,"amountB:",amountB);
    }
}
