// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Router02} from "../src/UniswapV2Router02.sol";
import {ERC20Token} from "../src/test/ERC20Token.sol";
import {UniswapV2ERC20} from "../src/UniswapV2ERC20.sol";

contract MyDex {
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    ERC20Token public WETH;
    ERC20Token public USDT;
    ERC20Token public RNT;

    event AddLiquidity(address account, uint amountInToken, uint amountInETH, uint liquidity);
    event SellETH(address account, address buyToken, uint256 sellEthAmount);
    event BuyETH(address account, address sellToken, uint256 sellAmount);

    constructor(address _factory, address _WETH, address _router, address _USDT, address _RNT) {
        factory = UniswapV2Factory(_factory);
        WETH = ERC20Token(_WETH);//使用假WETH（ERC20）测试,WETH未与ETH关联
        router = UniswapV2Router02(payable(_router));
        USDT = ERC20Token(_USDT);
        RNT = ERC20Token(_RNT);

        WETH.approve(address(router), ~uint256(0));
        USDT.approve(address(router), ~uint256(0));
    }

    function addLiquidity(uint amountInToken, uint amountInETH) public {
        USDT.transferFrom(msg.sender, address(this), amountInToken);
        WETH.transferFrom(msg.sender, address(this), amountInETH);
        (, , uint liquidity) = router
            .addLiquidity(
                address(USDT),
                address(WETH),
                amountInToken,
                amountInETH,
                0,
                0,
                msg.sender,
                block.timestamp
            );

        require(liquidity > 0, "addLiquidityETH fail");

        emit AddLiquidity(msg.sender, amountInToken, amountInETH, liquidity);
    }

    function sellETH(
        address buyToken,
        uint256 sellEthAmount,
        uint256 minBuyAmount
    ) external {
        WETH.transferFrom(msg.sender, address(this), sellEthAmount);
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = buyToken;
        router.swapExactTokensForTokens(
            sellEthAmount,
            minBuyAmount,
            path,
            msg.sender,
            block.timestamp
        );

        emit SellETH(msg.sender, buyToken, sellEthAmount);
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
        router.swapExactTokensForTokens(
            sellAmount,
            minBuyAmount,
            path,
            msg.sender,
            block.timestamp
        );

        emit BuyETH(msg.sender, sellToken, sellAmount);
    }
}
