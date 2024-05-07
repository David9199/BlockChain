// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract INSToken is ERC20 {
    uint256 public perMint;
    uint256 public topMint;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _perMint
    ) ERC20(_name, _symbol) {
        topMint = _totalSupply;
        perMint = _perMint;
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public onlyOwner returns (bool) {
        require(totalSupply() + perMint * amount <= topMint, "exceed totalSupply");
        _mint(address(to), perMint * amount);
        return true;
    }
}
