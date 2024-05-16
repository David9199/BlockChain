// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Staking {
    uint256 public number;

    struct Stake {
        uint256 ethAmount;
        uint256 unDrawKKAmount;
        uint256 stakeAccumulatedInterestRate;
    }

    mapping(address => Stake) public stakes;

    uint256 public accumulatedInterestRate; //累计利率
    uint256 public lastBlock; //last update accumulatedInterestRate time
    uint256 public totalStakeEth;
    uint256 public perBlockMineKK = 10 * 10 ** 18;

    ERC20 public KK;

    event UserStake(
        address account,
        uint ethAmount,
        uint stakeAccumulatedInterestRate
    );
    event Unstake(address account, uint256 drawEthAmount, uint256 drawKKAmount);
    event Claim(address account, uint256 drawKKAmount);
    event UpdateAccumulatedInterestRate(
        uint256 preLastBlock,
        uint256 accumulatedInterestRate
    );

    constructor(address KKToken) {
        KK = ERC20(KKToken);
        lastBlock = block.number;
    }

    function stake() external payable {
        require(msg.value > 0, "wrong eth amount");

        _updateAccumulatedInterestRate();

        totalStakeEth += msg.value;

        uint256 unDrawKKAmount = earned(msg.sender);

        Stake memory st = Stake(
            stakes[msg.sender].ethAmount + msg.value,
            unDrawKKAmount,
            accumulatedInterestRate
        );
        stakes[msg.sender] = st;

        emit UserStake(msg.sender, msg.value, accumulatedInterestRate);
    }

    function unstake() external {
        Stake storage st = stakes[msg.sender];
        require(st.ethAmount > 0, "not stake eth");

        _updateAccumulatedInterestRate();

        totalStakeEth -= st.ethAmount;

        uint256 unDrawKKAmount = earned(msg.sender);
        uint256 ethAmount = st.ethAmount;

        st.ethAmount = 0;
        st.unDrawKKAmount = 0;

        if (unDrawKKAmount > 0) {
            require(
                KK.transfer(msg.sender, unDrawKKAmount),
                "KK token transfer failed"
            );
        }

        payable(msg.sender).transfer(ethAmount);

        emit Unstake(msg.sender, ethAmount, unDrawKKAmount);
    }

    function claim() external {
        _updateAccumulatedInterestRate();

        uint256 unDrawKKAmount = earned(msg.sender);

        if (unDrawKKAmount > 0) {
            Stake storage st = stakes[msg.sender];

            st.unDrawKKAmount = 0;
            st.stakeAccumulatedInterestRate = accumulatedInterestRate;

            require(
                KK.transfer(msg.sender, unDrawKKAmount),
                "KK token transfer failed"
            );
        }

        emit Claim(msg.sender, unDrawKKAmount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return stakes[user].ethAmount;
    }

    function earned(address user) public view returns (uint256) {
        Stake memory st = stakes[user];
        if (st.ethAmount == 0) return 0;

        return
            st.unDrawKKAmount +
            (st.ethAmount *
                (accumulatedRate() - st.stakeAccumulatedInterestRate)) /
            10 ** 18;
    }

    function accumulatedRate() public view returns (uint256) {
        if (block.number == lastBlock || totalStakeEth == 0)
            return accumulatedInterestRate;
        return
            accumulatedInterestRate +
            ((block.number - lastBlock) * perBlockMineKK * 10 ** 18) /
            totalStakeEth;
    }

    function _updateAccumulatedInterestRate() private {
        if (block.number == lastBlock) return;
        if (totalStakeEth == 0) {
            lastBlock = block.number;
            return;
        }

        accumulatedInterestRate +=
            ((block.number - lastBlock) * perBlockMineKK * 10 ** 18) /
            totalStakeEth;
        emit UpdateAccumulatedInterestRate(lastBlock, accumulatedInterestRate);
        lastBlock = block.number;
    }
}
