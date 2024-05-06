// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract TokenBank {
    address public spaceToken = 0x6E111eaf89bbfC1210F413f63f0A35D34a75243f;

    mapping(address => mapping(address => uint256)) public userDeposit; //user --> token -->amount

    event Deposit(address indexed from, address indexed token, uint256 amount);

    event Withdraw(address indexed from, address indexed token, uint256 amount);

    constructor() {}

    function permitDeposit(
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20(token).permit(msg.sender, address(this), amount, deadline, v, r, s);

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        userDeposit[msg.sender][token] += amount;

        emit Deposit(msg.sender, token, amount);
    }

    function deposit(address token, uint256 amount) public {
        require(amount > 0, "amount is 0");
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= amount,
            "allowance not enough"
        );

        // IERC20(token).transferFrom(msg.sender, address(this), amount);
        bytes memory methodData = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            msg.sender,
            address(this),
            amount
        );
        (bool success, ) = token.call(methodData);
        require(success, "deposit failed");

        userDeposit[msg.sender][token] += amount;

        emit Deposit(msg.sender, token, amount);
    }

    function tokensReceived(
        address user,
        uint256 amount,
        bytes memory data
    ) public returns (bool) {
        require(amount > 0, "amount is 0");
        require(msg.sender == spaceToken, "must called by token");

        userDeposit[user][spaceToken] += amount;

        emit Deposit(user, spaceToken, amount);

        return true;
    }

    function withdraw(address token, uint256 amount) public {
        require(amount > 0, "amount is 0");
        uint256 depositAmount = userDeposit[msg.sender][token];
        require(depositAmount >= amount, "insufficient deposit balance");

        userDeposit[msg.sender][token] = depositAmount - amount;

        // IERC20(token).transfer(msg.sender, amount);
        bytes memory methodData = abi.encodeWithSignature(
            "transfer(address,uint256)",
            msg.sender,
            amount
        );
        (bool success, ) = token.call(methodData);
        require(success, "withdraw failed");

        emit Withdraw(msg.sender, token, amount);
    }
}
