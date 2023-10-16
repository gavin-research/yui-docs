---
sidebar_position: 5
---

# Execute token transfer

For the environment deployed so far,
Use `truffle console` to actually transfer the token.

The ledger and network name used here are as follows.
- IBC0 (network name is `ibc0`)
- IBC1 (network name is `ibc1`)

Execute the truffle console with a network name specified as follows.

````
truffle console --network=
    
````

The actors on the ledger are as follows for both ledgers.
- Alice (`accounts[1]`)
- Bob (`accounts[2]`)

## Check Alice and Bob's initial balances

Please confirm that the balance below is 0.

- Alice on IBC0
- Bob on IBC1

You can switch the network to connect and check as follows.

````js
// i = 1 for Alice, i = 2 for Bob
MiniToken.deployed()
    .then((instance) => instance.balanceOf(accounts[i]))
````

## Mint to Alice on ledger IBC0

Prepare only 100 MiniTokens for Alice.

````js
const accounts = await web3.eth.getAccounts();
const alice = accounts[1];

await MiniToken.deployed().then(instance => instance.mint(alice, 100));
````

If `mint` is successful, the `Mint` event is fired. To check this, do the following:

````js
MiniToken.deployed()
    .then(instance => instance.getPastEvents("Mint", { fromBlock: 0 }))
    .then(event => console.log(event));
````

## Token transfer from Alice on ledger IBC0 to Bob on ledger IBC1

Transfer 50 MiniTokens to Bob on IBC1.

````js
const port = "transfer";
const channel = "channel-0";

const bob = accounts[2];
await MiniToken.deployed()
    .then(instance => instance.sendTransfer(50, bob, port, channel, 0, {from: alice}));
````

## Check the MiniToken balance from Bob on ledger IBC1

It will take some time for the Packet to be received on the IBC1 side, but after that, you can confirm that the balance has increased as shown below.

````js
await MiniToken.deployed()
    .then((instance) => instance.balanceOf(bob));
````

   