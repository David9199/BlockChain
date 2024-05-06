// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {DotNFT} from "../src/DotNFT.sol";
import {NftMarket} from "../src/NftMarket.sol";
import {MessageHashUtils} from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract TokenBankTest is Test {
    bytes32 private _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    MyToken public MT;

    DotNFT public nft;

    NftMarket public market;

    uint privateKey = 1;
    address owner = vm.addr(privateKey);

    address tom = makeAddr("tom");

    function setUp() public {
        vm.startPrank(owner);
        MT = new MyToken();
        nft = new DotNFT();
        market = new NftMarket(address(MT));

        nft.mint(tom, "www.baidu.com");

        vm.stopPrank();
    }

    function test_list() public {
        vm.startPrank(tom);

        nft.setApprovalForAll(address(market), true);

        _list(1, 1000);
    }

    function _list(uint256 tokenId, uint256 price) private {
        market.list(address(nft), tokenId, price);

        assertEq(nft.ownerOf(tokenId), address(market),"nft transfer failed");
    }

    function test_PermitBuy() external {
        vm.startPrank(tom);
        nft.setApprovalForAll(address(market), true);
        uint256 tokenId = 1;
        _list(tokenId, 1000);
        vm.stopPrank();

        address whiteUser = address(1);
        assertEq(market.nonces(owner), 0);

        MT.mint(whiteUser, 10000);

        assertEq(market.owner(), owner);

        (uint8 v, bytes32 r, bytes32 s) = _getTypedDataSignature(
            privateKey,
            owner,
            whiteUser,
            address(nft),
            tokenId,
            market.nonces(whiteUser),
            1 hours
        );

        vm.startPrank(whiteUser);
        MT.approve(address(market), 10000);
        market.permitBuy(address(nft), tokenId, 1 hours, v, r, s);

        assertEq(nft.ownerOf(tokenId), whiteUser);
    }

    function _getTypedDataSignature(
        uint signerPrivateKey,
        address _owner,
        address spender,
        address nftAddr,
        uint tokenId,
        uint nonce,
        uint deadline
    ) private view returns (uint8, bytes32, bytes32){
        bytes32 structHash = keccak256(abi.encode(
            _PERMIT_TYPEHASH,
            // MT.PERMIT_TYPEHASH,
            _owner,
            spender,
            nftAddr,
            tokenId,
            nonce,
            deadline
        ));

        bytes32 digest = MessageHashUtils.toTypedDataHash(market.DOMAIN_SEPARATOR(), structHash);
        return vm.sign(signerPrivateKey, digest);
    }
    
}
