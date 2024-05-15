// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Router02} from "../src/UniswapV2Router02.sol";
import {ERC20Token} from "../src/test/ERC20Token.sol";
import {WETH9} from "../src/test/WETH.sol";
import {UniswapV2ERC20} from "../src/UniswapV2ERC20.sol";

contract MyDex2 {
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    WETH9 public WETH;
    ERC20Token public USDT;
    ERC20Token public RNT;

    event AddLiquidity(address account, uint amountInToken, uint amountInETH, uint liquidity);
    event SellETH(address account, address buyToken, uint256 sellEthAmount);
    event BuyETH(address account, address sellToken, uint256 sellAmount);

    constructor(address _factory, address _WETH, address _router, address _USDT, address _RNT) {
        factory = UniswapV2Factory(_factory);
        WETH = WETH9(payable(_WETH));//模拟真实WETH测试，WETH与ETH可1：1兑换
        router = UniswapV2Router02(payable(_router));
        USDT = ERC20Token(_USDT);
        RNT = ERC20Token(_RNT);

        WETH.approve(address(router), ~uint256(0));
        USDT.approve(address(router), ~uint256(0));
    }

    function addLiquidity(uint amountInToken) external payable {
        USDT.transferFrom(msg.sender, address(this), amountInToken);
        (, , uint liquidity) = router
            .addLiquidityETH{value: msg.value}(
                address(USDT),
                amountInToken,
                0,
                0,
                msg.sender,
                block.timestamp
            );

        require(liquidity > 0, "addLiquidityETH fail");

        emit AddLiquidity(msg.sender, amountInToken, msg.value, liquidity);
    }

    function sellETH(
        address buyToken,
        uint256 minBuyAmount
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = buyToken;
        router.swapExactETHForTokens{value: msg.value}(
            minBuyAmount,
            path,
            msg.sender,
            block.timestamp
        );

        emit SellETH(msg.sender, buyToken, msg.value);
    }

    function buyETH(
        address sellToken,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external {
        ERC20Token(sellToken).transferFrom(msg.sender, address(this), sellAmount);
        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = address(WETH);
        router.swapExactTokensForETH(
            sellAmount,
            minBuyAmount,
            path,
            msg.sender,
            block.timestamp
        );

        emit BuyETH(msg.sender, sellToken, sellAmount);
    }
}
