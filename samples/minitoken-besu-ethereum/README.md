minitoken
---

This is an example of an application using IBC to transfer [MiniToken](/contracts/minitoken/solidity) placed on two ledgers.

We use the following ledgers specifically:
- Hyperledger Besu
- Ethereum

# Preparation

As this example uses [Docker Compose v2](https://github.com/docker/compose#legacy), it is necessary to have at least Docker version 24.0.6. If you are using Windows (WSL), updating to the latest version of Docker Desktop is enough. For Linux, it is preferable to uninstall any previous packaged versions and perform a manual installation to ensure the latest Docker version through https://get.docker.com/."

```
$ docker version
Client: Docker Engine - Community
 Version:           24.0.6
 API version:       1.43
 Go version:        go1.20.7
 Git commit:        ed223bc
 Built:             Mon Sep  4 12:31:44 2023
 OS/Arch:           linux/amd64
 Context:           default
```

Also getting [nvm](https://github.com/nvm-sh/nvm) will make easier to get a `node` and `npm` tested for local deploy. In this example, the lastest node version works fine:

```
$ nvm install --lts
$ node -v
v18.18.0
$ npm -v
9.8.1
```

After that, execute `npm install` in the following directories.

- contracts/minitoken/solidity

In case using also Besu as client, it's also necesary compile this script:

- samples/minitoken-besu-ethereum (in this case, `postinstall` parameter in package.json finish the installation with `npm run compile:ibc`)

Also this module is needed:

```
$ npm install @truffle/hdwallet-provider -g
```

# Setup

The following will start the ledger, deploy the contract, and establish the channel with a relayer:

```
make setup
```
... or execute this step-by-step guide:

```
make build
make network
make migrate
make handshake
make relayer-start
```

If you want to do each setup independently, see [Makefile](/samples/minitoken/Makefile)
for more information.

# E2E

Perform E2E test to transfer MiniToken between ledgers:

```
make e2e
```
... or execute this step-by-step guide:

```
$ truffle exec test/0-init.js --network=ibc0 
$ truffle test test/0-init.test.js --network=ibc0 --compile-none --migrate-none
$ truffle exec test/1-send.js --network=ibc0
$ truffle test test/1-send.test.js --network=ibc0 --compile-none --migrate-none
$ truffle test test/2-ibc1.test.js --network=ibc1 --compile-none --migrate-none
$ truffle test test/3-ibc0.test.js --network=ibc0 --compile-none --migrate-none

```
# Clean Up

Stop the ledger and Relayer:

```
make down
```
