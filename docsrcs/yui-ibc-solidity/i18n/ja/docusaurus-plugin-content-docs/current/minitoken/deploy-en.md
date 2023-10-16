---
sidebar_position: 4
---

# Deploy Contract

Next, we will deploy Contract.

## Register MiniToken to IBCHandler

This tutorial uses Truffle to deploy Contracts.
As usual, migration management such as contract deployment is done in files under the `migrations` directory.
Regarding Truffle migration [here](https://www.trufflesuite.com/docs/truffle/getting-started/running-migrations)
Please refer to.

When IBCHandler receives a Packet, how to call the appropriate Contract according to the receiving port specified in the Packet
Use `IBCHandler.bindPort`.

As seen in `migrations/2_token_migration.js`,
After deploying each Contract, we associate the MiniToken with the `transfer` Port.

````js
const PortTransfer = "transfer";
ibcHandler.bindPort(PortTransfer, MiniToken.address);
````

## Building and deploying the environment

Here, we will build the required environment by simply running the following:

````
make setup
````

Specifically, the above command does the following:
- Building ledgers and relayers
- Launch two ledger networks
- Deploy Contract to ledger
- Start Relayer and perform handshake between two ledgers

To exit the environment, run:

````
make down
````