---
sidebar_position: 3
---

# Create Contract

We will implement a token that can be transferred between two ledgers using IBC.

[ICS-20](https://github.com/cosmos/ibc/tree/main/spec/app/ics-020-fungible-token-transfer)
There is a token transfer standard, but it is not supported here.

In ICS-20, the issuer of the token is distinguished using denomination, but in the MiniToken implemented this time, the ledger of the issuer is handled without distinction.

## Basic functions


It has the following basic operating functions.

- `mint`: Issue a new token to the specified account
- `burn`: Amortize own token
- `transfer`: Transfer your token to another account

It also has a status reference function.
- `balanceOf`: Get the token balance of an account

It has the following status:
- `balances`: Token balance of each account
- `owner`: Account that is allowed privileged operations such as mint

### constructor

Here, we simply assume that the account that generated the contract is the owner.

```solidity title="contracts/app/MiniToken.sol"
address private owner;

constructor() {
    owner = msg.sender;
}
````
### mint

Increases tokens by the specified amount for the specified account.
`_mint` is defined because we want to call the logic later from other internal processing.

```solidity
mapping(address => uint256) private _balances;

function mint(address account, uint256 amount) onlyOwner external {
    require(_mint(account, amount), "invalid address");
}

function _mint(address account, uint256 amount) internal returns (bool) {
    if (account == address(0)) {
        return false;
    }
    _balances[account] += amount;
    return true;
}
````

I will not cover the explanation of modifier implementations such as `onlyOwner`, but if you are interested, please refer to the source code.

### burn

Reduces tokens by the specified amount for the specified account.

```solidity
function burn(address account, uint256 amount) onlyOwner external {
    _burn(account, amount);
}

function _burn(address account, uint256 amount) internal returns (bool) {
    uint256 accountBalance = _balances[account];
    if (accountBalance < amount) {
        return false;
    }
    _balances[account] = accountBalance - amount;
    return true;
}
````

### transfer

Send the token to another account.

```solidity
function transfer(address to, uint256 amount) external {
    require(to != address(0), "Token: invalid address");
    uint256 balance = _balances[msg.sender];
    require(_balances[msg.sender] >= amount, "Token: amount shortage");
    _balances[msg.sender] -= amount;
    _balances[to] += amount;
}
````

### balanceOf

Get account balance.

```solidity
function balanceOf(address account) external view returns (uint256) {
    require(account != address(0), "Token: invalid address");
    return _balances[account];
}
````

## IBC related

Based on the above basic functions, we will implement the necessary processing for IBC.

### Packet

Define IBC Packet used for communication between ledgers.

For those who want to know more about Packet
[ICS 004](https://github.com/cosmos/ibc/tree/main/spec/core/ics-004-channel-and-packet-semantics)
Please refer to.

MiniTokenPacketData holds the information necessary to transfer MiniTokens from the source ledger to the destination ledger.

```proto title="/proto/lib/Packet.proto"
message MiniTokenPacketData {
    // the token amount to be transferred
    uint64 amount = 1;
    // the sender address
    bytes sender = 2;
    // the recipient address on the destination chain
    bytes receiver = 3;
}
````

- amount: amount of tokens to send
- sender: Source account on the source ledger
- receiver: remittance account on the destination ledger

After defining the Packet
Generate a sol file using [solidity-protobuf](https://github.com/datachainlab/solidity-protobuf).

First, get solidity-protobuf and install the required modules.
For details on the revision specified by yui-ibc-solidity, please see below.

https://github.com/hyperledger-labs/yui-ibc-solidity/tree/v0.3.3#for-developers

```sh
git clone https://github.com/datachainlab/solidity-protobuf.git
cd solidity-protobuf
git checkout fce34ce0240429221105986617f64d8d4261d87d
pip install -r requirements.txt
````

Next, generate a sol file in the working directory.

```sh
cd
    
make SOLPB_DIR=/path/to/solidity-protobuf proto-sol
````

### constructor renovation

The following can be specified to MiniToken as the IBC/TAO layer contract defined by yui-ibc-solidity.
The TAO layer stands for "transport, authentication, & ordering" and handles the core functionality of IBC that is independent of application logic.

-IBCHandler

```solidity
IBCHandler ibcHandler;

constructor(IBCHandler ibcHandler_) {
    owner = msg.sender;
    ibcHandler = ibcHandler_;
}
````

### sendTransfer

Add new operation functions to Token.
`sendTransfer` is a method to send a token to the other party's ledger using the MiniTokenPacketData defined earlier.

```solidity
function sendTransfer(
    string calldata denom,
    uint64 amount,
    address receiver,
    string calldata sourcePort,
    string calldata sourceChannel,
    uint64 timeoutHeight
) external {
    require(_burn(msg.sender, amount));

    _sendPacket(
        MiniTokenPacketData.Data({
            amount: amount,
            sender: abi.encodePacked(msg.sender),
            receiver: abi.encodePacked(receiver)
        }),
        sourcePort,
        sourceChannel,
        timeoutHeight
    );
}
````

Next, implement the Packet registration process `_sendPacket`.
By calling `IBCHandler.sendPacket`, the packet to be sent is registered.

```solidity
function _sendPacket(MiniTokenPacketData.Data memory data, string memory sourcePort, string memory sourceChannel, uint64 timeoutHeight) virtual internal {
    (Channel.Data memory channel, bool found) = ibcHandler.getChannel(sourcePort, sourceChannel);
    require(found, "channel not found");
    ibcHandler.sendPacket(Packet.Data({
        sequence: ibcHandler.getNextSequenceSend(sourcePort, sourceChannel),
        source_port: sourcePort,
        source_channel: sourceChannel,
        destination_port: channel.counterparty.port_id,
        destination_channel: channel.counterparty.channel_id,
        data: MiniTokenPacketData.encode(data),
        timeout_height: Height.Data({revision_number: 0, revision_height: timeoutHeight}),
        timeout_timestamp: 0
    }));
}
````

### IIBCModule

It is necessary to have the MiniToken call back when the IBC Module receives a Channel handshake or a packet.
[IIBCModule](https://github.com/hyperledger-labs/yui-ibc-solidity/blob/v0.3.3/contracts/core/05-port/IIBCModule.sol) interface defined in yui-ibc-solidity We will implement it.

```solidity
interface IIBCModule {
    function onChanOpenInit(
        Channel.Order,
        string[] calldata connectionHops,
        string calldata portId,
        string calldata channelId,
        ChannelCounterparty.Data calldata counterparty,
        string calldata version
    ) external;

    function onChanOpenTry(
        Channel.Order,
        string[] calldata connectionHops,
        string calldata portId,
        string calldata channelId,
        ChannelCounterparty.Data calldata counterparty,
        string calldata version,
        string calldata counterpartyVersion
    ) external;

    function onChanOpenAck(string calldata portId, string calldata channelId, string calldata counterpartyVersion) external;

    function onChanOpenConfirm(string calldata portId, string calldata channelId) external;

    function onChanCloseInit(string calldata portId, string calldata channelId) external;

    function onChanCloseConfirm(string calldata portId, string calldata channelId) external;

    function onRecvPacket(Packet.Data calldata, address relayer) external returns (bytes memory);

    function onAcknowledgementPacket(Packet.Data calldata, bytes calldata acknowledgment, address relayer) external;
}
````

Of the above, processing related to tokens is mainly handled below.
- onRecvPacket
- onAcknowledgementPacket

If there is a process that you want to perform when establishing a channel between ledgers, you need to implement the following process.
This is not a particular consideration in this case.
- onChanOpenInit
- onChanOpenTry
- onChanOpenAck
- onChanOpenConfirm
- onChanCloseInit
- onChanCloseConfirm

If you would like to know more about the channel lifecycle in IBC, please see below.

https://github.com/cosmos/ibc/blob/main/spec/core/ics-004-channel-and-packet-semantics/README.md

#### onRecvPacket

Creates a new token for the specified remittance account according to the contents of the packet.

Called when MiniTokenPacketData is received on the token transfer destination ledger.

Returns the success or failure of the process as Acknowledgment.

```solidity
function onRecvPacket(Packet.Data calldata packet, address relayer) onlyIBC external virtual override returns (bytes acknowledge memoryment) {
    MiniTokenPacketData.Data memory data = MiniTokenPacketData.decode(packet.data);
    return _newAcknowledgement(
        _mint(data.receiver.toAddress(), data.amount)
    );
}
````

#### onAcknowledgementPacket

If the process fails at the destination, we will redeem the tokens to the source account.

Called when Acknowledgment is received on the token transfer ledger.


```solidity
function onAcknowledgementPacket(Packet.Data calldata packet, bytes calldata acknowledgment, address relayer) onlyIBC external virtual override {
    if (!_isSuccessAcknowledgement(acknowledgement)) {
        _refundTokens(MiniTokenPacketData.decode(packet.data));
    }
}
````

## Items not covered here

The token we implemented this time is different from ICS-20, but we will introduce some of the differences here.

Please refer to the following for an example of implementing ICS-20.

https://github.com/hyperledger-labs/yui-ibc-solidity/tree/v0.3.3/contracts/apps

### Distinction between monetary units

ICS-20 uses the currency unit (denomination or denom) as
Express as `{ics20Port}/{ics20Channel}/{denom}`.

It is possible to trace ICS-20 tokens back to their original chain using currency units. For more information, please see below.

https://github.com/cosmos/ibc-go/blob/main/docs/apps/transfer/overview.md#denomination-trace