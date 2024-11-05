require("web3")
const SCAccess = artifacts.require("SCAccess");
module.exports = async (callback) => {
    const accounts = await web3.eth.getAccounts();
    const alice = accounts[1];
    const bob = accounts[2];
//

  const scAccess = await SCAccess.deployed();

  const gc = await scAccess.getPastEvents("Gavincall", {
    fromBlock: 0,
  });
  
  console.log(gc);
  callback();
};


