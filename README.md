# About THIS PROJECT

Project is based on the original proposal made by Hyperledger lab: YUI. A cross-chain solution to allow interopreability between blockchains.

The modifications made here are the following:

- Sending arbitrary data from Blockchain A to Blockchain B
- Automated execution on Blockchain B of the sending function in order to return a data to Blockchain A after being called
- Storage of the Blockchain B data on the Blockchain A once received automatically.
- Use of two Ethereum based blockchains (geth)

This functionalities allow to call from a Blockchain A to a Blockchain B for a data stored exclusively on B and bring it to A without an active member on B sending the information back to A.

# Preparation

Execute `npm install` in the following order on these directories to install dependencies.

- *contracts/minitoken/solidity*
- *contracts/minitoken/solidityB2*
- *contracts/minitoken/solidityPrivada*
- *samples/minitoken-ethereum-ethereum*

Once installed, first make sure that on:

- *samples/minitoken-ethereum-ethereum/truffle-config.js*

The following variables are written referring to contract_dir as:
`contracts_directory: contract_dir,`
`contracts_build_directory: contract_dir + "/build/contracts",`
`migrations_directory: contract_dir + "/migrations",`

Execute `make setup`

After it make sure that in *contracts/minitoken/solidityB2/migrations/2-token_migration.js* the constant `const SCContrato = artifacts.require("SCData");` is like that, with SCData.

After it, update  *samples/minitoken-ethereum-ethereum/truffle-config.js* changing `contract_dir` for `contract_dir2` on the variables from before.

Execute `make setup2`

Execute `make relayer01` so the relayer between ibc0 (SCAccess) and ibc1 (SCData) starts running.

IN ANOTHER CONSOLE:

After it, update  *samples/minitoken-ethereum-ethereum/truffle-config.js* changing `contract_dir2` for `contract_dir3` on the variables from before.

Execute `make setupPr`

After it make sure that in *contracts/minitoken/solidityB2/migrations/2-token_migration.js* the constant `const SCContrato = artifacts.require("SCStorage");` is like that, with SCStorage.

After it, update  *samples/minitoken-ethereum-ethereum/truffle-config.js* changing `contract_dir3` for `contract_dir2` on the variables from before.

Execute `make setup2`
Write down the address of the contract OwnableIBCHandler showed in console during migrations when deployed.

Go to `samples/minitoken/configs/relayer/demo/ibc-1.json` and change `"ibc_address":0x...` to that one.

Execute `make relayerPr1` so the relayer between ibc2 (Privada) and ibc1 (SCData) starts running. 


# Tests

Before executing the tests, make sure that you change back *samples/minitoken-ethereum-ethereum/truffle-config.js* `contract_dir2` to `contract_dir` on the variables from before.

This is because all interactions are made from the Blockchain A, and Blockchain B will return values through the IBC without needing of an active party interacting with it on the other side.

You can execute the following tests for the connection IBC0-IBC1 from *samples/minitoken-ethereum-ethereum* to check the functioning of the project:

- `npx truffle exec test/0-grantaccess.js --network=ibc0`
- `npx truffle exec test/1-send.js --network=ibc0`
- `npx truffle test test/1-send.test.js --network=ibc0 --compile-none --migrate-none`
- `npx truffle test test/2-ibc1.test.js --network=ibc0 --compile-none --migrate-none`

These tests allow first to give access to Bob to Alice salted hash. Then Bob sends a token from Blockchain A and it arrives to Blockchain B through the IBC. The salted hash is immediately returned to Blockchain A automatically through the same IBC, so the owner can see they have the salted hash now on Blockchain A.

You can execute the following tests for the connection IBC2-IBC1 from *samples/minitoken-ethereum-ethereum* to check the functioning of the project:

- `npx truffle exec test/9-volcado.js --network=ibc0`
- `npx truffle test test/9-volcado.test.js --network=ibc0 --compile-none --migrate-none`

These tests allow you to send a new issued certificate data from the private blockchain with SCVolcado to the IBC1 SCStorage.

# YUI

"YUI" is japanese word to represent knot, join and connect

# About YUI:

YUI is a lab to achieve interoperability between multiple heterogeneous ledgers. YUI provides modules and middleware for cross-chain communication as well as modules and tools for cross-chain application development, including an explorer to track status and events for cross-chain environments.

For cross-chain communication, the design of YUI is based on Inter Blockchain Communication (IBC) protocol by Cosmos project, with extensions to support various Hyperledger projects.

Modules for cross-chain application development includes one that implements a protocol for atomic operations between ledgers, such as atomic swap of tokens.

## More information

For more information about YUI, you can find here the original project: 
- https://github.com/hyperledger-labs/yui-docs/

### YUI Committers

- Jun Kimura - https://github.com/bluele
- Ryo Sato - https://github.com/3100
- Masanori Yoshida - https://github.com/siburu

### YUI Contributors

Please take a look at [CONTRIBUTORS.md](./CONTRIBUTORS.md)

### YUI Repositories

- https://github.com/hyperledger-labs/yui-fabric-ibc
- https://github.com/hyperledger-labs/yui-ibc-solidity
- https://github.com/hyperledger-labs/yui-corda-ibc
- https://github.com/hyperledger-labs/yui-relayer
