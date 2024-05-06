// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract DotNFT is ERC721URIStorage {
    address public owner;

    uint256 counter;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() ERC721("DOTNFT", "DOT") {
        owner = msg.sender;
    }

    function mint(address to, string memory tokenURI) public onlyOwner returns (uint256) {
        counter++;
        uint256 newItemId = counter;
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}
