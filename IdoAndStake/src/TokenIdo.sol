// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/libraries/TransferHelper.sol";

contract TokenIdo {
    struct Ido {
        address launcher;
        uint256 start;
        uint256 end;
        uint256 tokenAmount;
        uint256 softTop;
        uint256 hardTop;
        uint256 minValue;
        uint256 idoValue;
    }

    mapping(address => Ido) public idos;
    mapping(address => mapping(address => bool)) public isRetrieve;
    mapping(address => mapping(address => uint256)) public myPresale;
    mapping(address => mapping(address => bool)) public isRefund;

    constructor() {}

    function launch(
        address token,
        uint256 start,
        uint256 end,
        uint256 tokenAmount,
        uint256 softTop,
        uint256 hardTop,
        uint256 minIdo
    ) external payable {
        require(msg.value >= 1 ether, "Below minimum value");

        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            tokenAmount
        );

        idos[token] = Ido(
            msg.sender,
            start,
            end,
            tokenAmount,
            softTop,
            hardTop,
            minIdo,
            0
        );
    }

    function presale(address token) external payable {
        require(block.timestamp > idos[token].start, "Not start");
        require(block.timestamp < idos[token].end, "Has ended");
        require(msg.value >= idos[token].minValue, "Below minimum value");
        require(
            idos[token].idoValue + msg.value <= idos[token].hardTop,
            "Has ended"
        );

        idos[token].idoValue += msg.value;

        myPresale[msg.sender][token] += msg.value;
    }

    function refund(address token) external {
        require(
            block.timestamp > idos[token].end ||
                idos[token].idoValue >= idos[token].softTop,
            "Not end"
        );
        require(myPresale[msg.sender][token] > 0, "You didn't participate");
        require(!isRefund[msg.sender][token], "Has refund");

        if (idos[token].idoValue >= idos[token].softTop) {
            uint256 amount = (idos[token].tokenAmount *
                myPresale[msg.sender][token]) / idos[token].idoValue;
            uint256 balance = IERC20(token).balanceOf(address(this));
            amount = amount < balance ? amount : balance;

            TransferHelper.safeTransfer(token, msg.sender, amount);
        } else {
            isRefund[msg.sender][token] = true;
            TransferHelper.safeTransferETH(
                msg.sender,
                myPresale[msg.sender][token]
            );
        }
    }

    function retrieve(address token) external {
        require(
            block.timestamp > idos[token].end ||
                idos[token].idoValue >= idos[token].softTop,
            "Not end"
        );
        require(msg.sender == idos[token].launcher, "You are not the launcher");
        require(idos[token].idoValue >= idos[token].softTop, "Launch failed");
        require(!isRetrieve[msg.sender][token], "Has retrieve");

        isRetrieve[msg.sender][token] = true;
        TransferHelper.safeTransferETH(msg.sender, idos[token].idoValue);
    }
}
