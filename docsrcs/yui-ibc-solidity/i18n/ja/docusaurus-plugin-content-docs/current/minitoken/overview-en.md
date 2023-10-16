---
sidebar_position: 1
---

# overview

In this tutorial,
[yui-ibc-solidity](https://github.com/hyperledger-labs/yui-ibc-solidity)
I'll walk you through the process of building your first IBC application.
At the time of writing the tutorial
[v0.3.3](https://github.com/hyperledger-labs/yui-ibc-solidity/tree/v0.3.3)
is used.

Create a smart contract that can transfer tokens between two ledgers using IBC.

Learn how below.
- Create and send packets between blockchains using IBC
- Create basic tokens and send tokens to another blockchain

Here, we will explain smart contracts using Solidity.
In addition, we will use the following ledger.
-Hyperledger Besu
-Ethereum

For those who want to know more about IBC
[cosmos/ibc](https://github.com/cosmos/ibc)
Please refer to.

Also, this tutorial is [hyperledger-labs/yui-ibc-solidity](https://github.com/hyperledger-labs/yui-ibc-solidity)
Since it depends on the IBC Solidity implementation provided by
[README](https://github.com/hyperledger-labs/yui-ibc-solidity#readme), architecture and other information
[docs](https://github.com/hyperledger-labs/yui-ibc-solidity/tree/main/docs)
Please refer to

The code for this tutorial is available below, so please refer to it as appropriate.
- [Contract](https://github.com/hyperledger-labs/yui-docs/tree/main/contracts/minitoken/solidity)
- [Execution environment](https://github.com/hyperledger-labs/yui-docs/tree/main/samples/minitoken-besu-ethereum)