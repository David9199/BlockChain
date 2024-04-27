// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MyNFTMarket} from "../src/MyNFTMarket.sol";
import {SpaceNFT} from "../src/SpaceNFT.sol";
import {SpaceToken} from "../src/SpaceToken.sol";
import {IERC20Errors} from "../lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";

contract MyNFTMarketTest is Test {
    MyNFTMarket public market;
    SpaceNFT public nft;
    SpaceToken public token;

    address tom = makeAddr("tom");

    function setUp() public {
        vm.startPrank(tom);

        market = new MyNFTMarket();
        nft = new SpaceNFT();
        token = new SpaceToken();

        nft.mint(tom, "www.baidu.com");
        market.updateSPACE(address(token));

        vm.stopPrank();
    }

    function test_list() public {
        vm.startPrank(tom);

        nft.setApprovalForAll(address(market), true);

        _list(1, 1000);
    }

    /// forge-config: default.fuzz.runs = 600
    function test_listRandom(uint256 price) public {
        vm.assume(price > 0);

        vm.startPrank(tom);

        nft.setApprovalForAll(address(market), true);

        _list(1, price);
    }

    function _list(uint256 tokenId, uint256 price) private {
        market.list(address(nft), tokenId, price);

        assertEq(nft.ownerOf(tokenId), address(market),"nft transfer failed");
    }

    function testFailed_needApprovedFirst() public {
        vm.startPrank(tom);

        // nft.setApprovalForAll(address(market), true);

        _list(1, 1000);
    }

    function test_buy() public {
        vm.startPrank(tom);

        nft.setApprovalForAll(address(market), true);

        _list(1, 1000);

        address bob = makeAddr("bob");

        token.transfer(bob, 1000000000);

        vm.startPrank(bob);

        token.approve(address(market), 1000000000);

        _buy(bob, 1);

        vm.stopPrank();
    }
    
    function testBuyerCanNotBeSeller() public {
        vm.startPrank(tom);

        nft.setApprovalForAll(address(market), true);

        _list(1, 1000);

        token.approve(address(market), 1000000000);
        vm.expectRevert("buyer can not be seller");
        _buy(tom, 1);

        // address bob = makeAddr("bob");

        // token.transfer(bob, 1000000000);

        // vm.startPrank(bob);
        // bytes memory errorInfo= abi.encode(address(market),0,1000);

        // token.approve(address(market), 1000000000);
        // vm.expectRevert("");
        // _buy(bob, 1);

        vm.stopPrank();
    }

    function _buy(address buyer, uint256 tokenId) private {
        address seller = market.nftSeller(address(nft),tokenId);

        uint256 preBalance = token.balanceOf(seller);

        uint256 price = market.nftPrice(address(nft),tokenId);

        market.buyNFT(address(nft), tokenId);

        assertEq(nft.ownerOf(tokenId), buyer,"nft transfer failed");
        assertEq(token.balanceOf(seller), preBalance + price,"token transfer failed");
    }
}
