import { configConn } from './config'
import { parseAbiItem } from 'viem'

function bigintToStr6(aBigint: bigint) {
    const dd = aBigint/1000000n;
    const xx = aBigint % 1000000n;
    return ""+dd+"."+xx;
}

const usdcAddr = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"

async function printUsdcTransfer100Block() {
    const blockNumber = await configConn.getBlockNumber(); // 区块高度
    console.log(blockNumber,'区块高度=======');
    const begin = blockNumber - BigInt(100);
    const end = blockNumber
    console.log("查询区块范围: " + begin + " - " + end +"(含)");

    const filter = await configConn.createEventFilter({
        address: usdcAddr,
        event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'), 
        fromBlock: begin,
        toBlock: end
    });

    const logs = await configConn.getFilterLogs({filter});

    logs.forEach((log) => {
        console.log(`从 ${log.args.from} 转账给 ${log.args.to} ${bigintToStr6(log.args.value!)} USDC ,交易ID：${log.transactionHash}`);
    });
}


printUsdcTransfer100Block().catch((err) => {
    console.log(err);
});
