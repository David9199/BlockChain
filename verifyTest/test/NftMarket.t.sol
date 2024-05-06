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

    function getMessageHash(string memory _message) public pure returns (bytes32){
    // function getMessageHash(string memory _message) public pure returns (bytes32){

        // return keccak256(abi.encodePacked(_message));
        return keccak256(abi.encodePacked(_message));

    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32){

        // return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
        return _messageHash;

    }

    function getSigner(bytes32 _ethSignedMessageHash, bytes memory _sign) public pure returns(address){

        (bytes32 r, bytes32 s, uint8 v) = splitSign(_sign);

        return ecrecover(_ethSignedMessageHash, v, r, s); //返回签名者地址

    }

    function splitSign(bytes memory _sign) public pure returns (bytes32 r, bytes32 s, uint8 v){

        assembly {

            r := mload(add(_sign, 32))

            s := mload(add(_sign, 64))

            v := byte(0, mload(add(_sign, 96)))

        }

    }

    function verify(address _signer, string memory _message, bytes memory _sign) external pure returns (bool){

        bytes32 messageHash = getMessageHash(_message);

        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        address signer = getSigner(ethSignedMessageHash, _sign);

        if(signer == _signer){

            return true;

        }

        return false;

    }

    
}
