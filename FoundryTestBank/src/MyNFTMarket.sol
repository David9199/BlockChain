// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyNFTMarket {
    event List(
        address indexed user,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price
    );
    event Cancel(
        address indexed user,
        address indexed nftAddress,
        uint256 tokenId
    );
    event BuyNFT(
        address indexed user,
        address indexed preOwner,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price
    );

    struct SaleNFT {
        address seller;
        uint256 price;
        uint256 onSaleTime;
        bool onSale;
    }

    mapping(address => mapping(uint256 => SaleNFT)) public saleNfts;

    ERC20 SPACE;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        SPACE = ERC20(0x6E111eaf89bbfC1210F413f63f0A35D34a75243f);
    }

    function updateSPACE(address token) external onlyOwner {
        SPACE = ERC20(token);
    }

    function rescueToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function list(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        require(msg.sender == ERC721(nftAddress).ownerOf(tokenId), "not owner");
        require(price > 0, "price error");

        saleNfts[nftAddress][tokenId] = SaleNFT(
            msg.sender,
            price,
            _getTs(),
            true
        );

        ERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);

        emit List(msg.sender, nftAddress, tokenId, price);
    }

    function cancel(address nftAddress, uint256 tokenId) external {
        require(
            msg.sender == saleNfts[nftAddress][tokenId].seller,
            "not owner"
        );

        saleNfts[nftAddress][tokenId].onSale = false;

        ERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        emit Cancel(msg.sender, nftAddress, tokenId);
    }

    function buyNFT(address nftAddress, uint256 tokenId) external {
        require(msg.sender != saleNfts[nftAddress][tokenId].seller, "buyer can not be seller");
        uint256 price = saleNfts[nftAddress][tokenId].price;
        uint256 tokenBalance = SPACE.balanceOf(msg.sender);
        require(tokenBalance >= price, "balance error");
        // require(SPACE.allowance(msg.sender, address(this)) >= price, "allowance error");

        address seller = saleNfts[nftAddress][tokenId].seller;

        require(
            SPACE.transferFrom(msg.sender, seller, price),
            "transfer error"
        );

        _buyNFT(msg.sender, nftAddress, tokenId);
    }

    function tokensReceived(
        address buyer,
        uint256 amount,
        bytes memory data
    ) public returns (bool) {
        require(msg.sender == address(SPACE), "must called by token");

        (address nftAddress, uint256 tokenId) = abi.decode(
            data,
            (address, uint256)
        );

        uint256 price = saleNfts[nftAddress][tokenId].price;
        require(amount >= price, "amount not enough");

        address seller = saleNfts[nftAddress][tokenId].seller;

        require(SPACE.transfer(seller, price), "transfer error");

        _buyNFT(buyer, nftAddress, tokenId);

        return true;
    }

    function _buyNFT(
        address buyer,
        address nftAddress,
        uint256 tokenId
    ) private {
        require(saleNfts[nftAddress][tokenId].onSale, "selled");

        saleNfts[nftAddress][tokenId].onSale = false;

        ERC721(nftAddress).transferFrom(address(this), buyer, tokenId);

        emit BuyNFT(
            buyer,
            saleNfts[nftAddress][tokenId].seller,
            nftAddress,
            tokenId,
            saleNfts[nftAddress][tokenId].price
        );
    }

    function _getTs() internal view returns (uint64) {
        return uint64(block.timestamp);
    }

    function nftPrice(address nftAddress, uint256 tokenId) public view returns (uint256) {
        return saleNfts[nftAddress][tokenId].price;
    }

    function nftSeller(address nftAddress, uint256 tokenId) public view returns (address) {
        return saleNfts[nftAddress][tokenId].seller;
    }
}
