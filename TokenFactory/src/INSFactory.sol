// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./INSToken.sol";
import "../lib/libraries/TransferHelper.sol";

contract INSFactory {
    mapping(address => uint256) public price;
    mapping(address => address) public creator;
    mapping(address => address) public project;

    constructor() {}

    function deployInscription(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _perMint,
        uint256 _price,
        address _project
    ) public returns (address) {
        INSToken token = new INSToken(_name, _symbol, _totalSupply, _perMint);
        price[address(token)] = _price;
        creator[address(token)] = msg.sender;
        project[address(token)] = _project;

        return address(token);
    }

    function mintInscription(address tokenAddr, uint256 amount) public payable {
        require(msg.value == price[tokenAddr] * amount, "price error");

        require(INSToken(tokenAddr).mint(msg.sender, amount), "mint error");

        uint256 creatorValue = msg.value / 2;
        uint256 projectValue = msg.value - creatorValue;
        TransferHelper.safeTransferETH(creator[tokenAddr], creatorValue);
        TransferHelper.safeTransferETH(project[tokenAddr], projectValue);
    }
}
