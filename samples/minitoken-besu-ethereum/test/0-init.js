const MiniMessage = artifacts.require("MiniMessage");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const alice = accounts[1];
  const mensajillo = "cacnea";

  const miniMessage = await MiniMessage.deployed();
  const block = await web3.eth.getBlockNumber();

  await miniMessage.mint(alice, mensajillo);
  const mintEvent = await miniMessage.getPastEvents("Mint", { fromBlock: block });
  console.log(mintEvent);

  callback();
};
