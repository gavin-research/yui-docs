const MiniMessage = artifacts.require("MiniDelegateB1");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const alice = accounts[1];
  const bob = accounts[2];

  const sendAmount = "0x05416460deb76d57af601be17e777b93592d8d4d4a4096c57876a91c84f4a712";
  const port = "transfer";
  const channel = "channel-0";
  const timeoutHeight = 0;

  const miniMessage = await MiniMessage.deployed();

  await miniMessage.sendTransfer(sendAmount, bob, port, channel, timeoutHeight, {
    from: bob,
  });
 
  const sendTransfer = await miniMessage.getPastEvents("SendTransfer", {
    fromBlock: 0,
  });
  
  console.log(sendTransfer);

  callback();
};
