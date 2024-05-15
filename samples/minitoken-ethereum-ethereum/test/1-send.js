const SCAccess = artifacts.require("SCAccess");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const alice = accounts[1];
  const bob = accounts[2];

  const sendAmount = "0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e";
  const port = "transfer";
  const channel = "channel-0";
  const timeoutHeight = 0;

  const scaccess = await SCAccess.deployed();

  // bob solicita acceso para verificar el certificado cheddar
  await scaccess.sendTransfer(sendAmount, bob, port, channel, timeoutHeight, {
    from: bob,
  });

  const sendTransfer = await scaccess.getPastEvents("SendTransfer", {
    fromBlock: 0,
  });
  
  console.log(sendTransfer);

  callback();
};
