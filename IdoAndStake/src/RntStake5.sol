// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/libraries/TransferHelper.sol";

interface IEsRnt {
    function mint(address to) external returns (uint256);
    function retrieveRnt(address to) external returns (uint256);
    function burn(uint256 amount) external returns (bool);
}

library DateTime {
    function getNowDateTime() public view returns (uint32) {
        uint256 ts = block.timestamp + 8 hours;
        return uint32(ts / 1 days);
    }

    function tsToDateTime(uint256 ts) public pure returns (uint32) {
        return uint32((ts + 8 hours) / 1 days);
    }
}

contract RntStake {
    event StakeRnt(address indexed user, uint256 rntAmount);
    event DrawEsRnt(address indexed user, uint256 esRntAmount);
    event RetrieveRnt(
        address indexed user,
        uint256 rntAmount,
        uint256 esRntAmount
    );
    event RntRelease(
        address indexed user,
        uint256 rntAmount,
        uint256 burnEsRntAmount
    );

    struct Stake {
        uint256 rntAmount;
        uint256 unDrawEsRnt;
        uint32 lastSettleDate;
    }

    mapping(address => Stake) public stakes;
    mapping(address => mapping(uint32 => uint256)) public esRntLocks;
    mapping(address => uint256) public releaseRnt;
    mapping(address => uint32) public lastReleaseDate;

    address public rnt;
    IEsRnt public esRnt;

    modifier beforeRnt() {
        _settleRnt();
        _;
    }

    modifier beforeEsRnt() {
        _settleEsRnt();
        _;
    }

    constructor(address _rnt, address _esRnt) {
        rnt = _rnt;
        esRnt = IEsRnt(_esRnt);
        IERC20(address(esRnt)).approve(
            address(esRnt),
            100000000000000000000000
        );
    }

    //质押RNT
    function stake(uint256 rntAmount) external beforeRnt {
        TransferHelper.safeTransferFrom(
            rnt,
            msg.sender,
            address(this),
            rntAmount
        );

        //质押以天为单位进行记录与结算
        if (stakes[msg.sender].rntAmount == 0) {
            stakes[msg.sender] = Stake(rntAmount, 0, DateTime.getNowDateTime());
        } else {
            stakes[msg.sender].rntAmount += rntAmount;
        }

        emit StakeRnt(msg.sender, rntAmount);
    }

    //领取质押收益
    function drawEsRnt() external beforeRnt {
        uint256 unDrawEsRnt = stakes[msg.sender].unDrawEsRnt;
        require(unDrawEsRnt > 0, "No profit to withdraw");

        stakes[msg.sender].unDrawEsRnt = 0;
        _mint(unDrawEsRnt);

        emit DrawEsRnt(msg.sender, unDrawEsRnt);
    }

    //取回质押
    function retrieveRnt() external beforeRnt {
        uint256 rntAmount = stakes[msg.sender].rntAmount;
        require(rntAmount > 0, "No token to retrieve");

        stakes[msg.sender].rntAmount = 0;
        TransferHelper.safeTransfer(rnt, msg.sender, rntAmount);

        uint256 unDrawEsRnt = stakes[msg.sender].unDrawEsRnt;
        if (unDrawEsRnt > 0) {
            stakes[msg.sender].unDrawEsRnt = 0;
            _mint(unDrawEsRnt);
        }

        emit RetrieveRnt(msg.sender, rntAmount, unDrawEsRnt);
    }

    //解锁esRNT
    function rntRelease(uint256 esRntAmount) external beforeEsRnt {
        uint256 _releaseRnt = releaseRnt[msg.sender];
        uint256 actualEsRnt;//提前解锁实际到手的EsRnt
        uint256 burnEsRnt;//提前解锁燃烧掉的EsRnt
        if (_releaseRnt < esRntAmount) {
            //提前解锁
            releaseRnt[msg.sender] = 0;
            uint32 nowDate = DateTime.getNowDateTime();
            uint32 start = lastReleaseDate[msg.sender] > nowDate - 29
                ? lastReleaseDate[msg.sender]
                : nowDate - 29;
            lastReleaseDate[msg.sender] > nowDate - 29;

            //用户提前解锁的部分
            uint256 redeemEsRnt = esRntAmount - _releaseRnt;
            uint256 expireEsRnt;
            uint256 esRntLock;
            for (uint32 i = start; i < nowDate; i++) {
                esRntLock = esRntLocks[msg.sender][i];
                if (esRntLock == 0) continue;
                expireEsRnt = (esRntLock * (nowDate - i)) / 30;
                burnEsRnt += (esRntLock - expireEsRnt);
                actualEsRnt += expireEsRnt;

                if (esRntLock >= redeemEsRnt) {
                    lastReleaseDate[msg.sender] = i;
                    break;
                } else {
                    redeemEsRnt = redeemEsRnt - esRntLock;
                }
                if (i + 1 == nowDate) {
                    lastReleaseDate[msg.sender] = i;
                }
            }
            actualEsRnt += _releaseRnt;
        } else {
            //到期解锁
            actualEsRnt = esRntAmount;
            releaseRnt[msg.sender] -= esRntAmount;
        }

        if (actualEsRnt > 0) {
            TransferHelper.safeTransferFrom(
                address(esRnt),
                msg.sender,
                address(esRnt),
                actualEsRnt
            );

            require(esRnt.retrieveRnt(msg.sender) > 0, "retrieve rnt fail");
        }

        if (burnEsRnt > 0) {
            TransferHelper.safeTransferFrom(
                address(esRnt),
                msg.sender,
                address(this),
                burnEsRnt
            );
            esRnt.burn(burnEsRnt);
        }

        emit RntRelease(msg.sender, actualEsRnt, burnEsRnt);
    }

    //根据质押收益铸造EsRnt
    function _mint(uint256 esRntAmount) private {
        TransferHelper.safeTransfer(rnt, address(esRnt), esRntAmount);

        require(esRnt.mint(msg.sender) > 0, "mint fail");
        uint32 nowDate = DateTime.getNowDateTime();
        esRntLocks[msg.sender][nowDate] += esRntAmount;
        if (lastReleaseDate[msg.sender] == 0) {
            lastReleaseDate[msg.sender] = nowDate;
        }
    }

    //结算质押收益
    function _settleRnt() private {
        if (stakes[msg.sender].rntAmount == 0) return;
        uint32 intervalDate = DateTime.getNowDateTime() -
            stakes[msg.sender].lastSettleDate;
        if (intervalDate == 0) return;

        uint256 unDrawEsRnt = stakes[msg.sender].rntAmount * intervalDate;
        stakes[msg.sender].unDrawEsRnt += unDrawEsRnt;
        stakes[msg.sender].lastSettleDate = DateTime.getNowDateTime();
    }

    //结算解锁的EsRnt
    function _settleEsRnt() private {
        uint32 _lastReleaseDate = lastReleaseDate[msg.sender];
        uint32 _nowDate = DateTime.getNowDateTime();

        if (_lastReleaseDate > 0) {
            if (_lastReleaseDate > _nowDate - 30) return;

            uint256 _releaseRnt;
            for (uint32 i = _lastReleaseDate; i < _nowDate - 29; i++) {
                _releaseRnt += esRntLocks[msg.sender][i];
            }

            releaseRnt[msg.sender] += _releaseRnt;
        }

        lastReleaseDate[msg.sender] = _nowDate - 29;
    }
}
