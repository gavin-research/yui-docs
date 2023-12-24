const MiniMessage = artifacts.require("MiniMessage");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const alice = accounts[1];
  const bob = accounts[2];

  const mintAmount = "cacnea";
  const sendAmount = "cacnea";
  const port = "transfer";
  const channel = "channel-0";
  const timeoutHeight = 0;

  const miniMessage = await MiniMessage.deployed();
  console.log("GROUDON");
  await miniMessage.sendTransfer(sendAmount, alice, port, channel, timeoutHeight, {
    from: alice,
  });
  console.log("combusken");
  const sendTransfer = await miniMessage.getPastEvents("SendTransfer", {
    fromBlock: 0,
  });
  console.log("blaziken");
  console.log(sendTransfer);

  callback();
};
