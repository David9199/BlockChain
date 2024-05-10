// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract esRntToken is ERC20 {
    uint256 public lastRntBalance;

    address public rnt;

    address public rntStake;

    modifier onlyMaster() {
        require(msg.sender == rntStake, "Not rntStake");
        _;
    }

    constructor() ERC20("esRnt", "esRNT") {
        // _mint(address(msg.sender), 100000000 * 10 ** decimals());
        rntStake = msg.sender;
    }

    function setRntStake(address _rntStake) external onlyMaster {
        rntStake = _rntStake;
    }

    function setRntToken(address _rntToken) external onlyMaster {
        rnt = _rntToken;
    }

    function mint(address to) external returns (uint256 amount) {
        if (IERC20(rnt).balanceOf(address(this)) > lastRntBalance) {
            amount = IERC20(rnt).balanceOf(address(this)) - lastRntBalance;
            lastRntBalance = IERC20(rnt).balanceOf(address(this));

            _mint(to, amount);
        }
        return amount;
    }

    function retrieveRnt(address to) external onlyMaster returns (uint256) {
        uint256 amount = balanceOf(address(this));
        if (amount > 0) {
            _burn(address(this), amount);
            require(IERC20(rnt).transfer(to, amount), "rnt transfer fail");
        }
        return amount;
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}
