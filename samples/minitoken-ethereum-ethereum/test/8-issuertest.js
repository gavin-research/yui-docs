require("web3")
const SCVolcado = artifacts.require("SCVolcado");
module.exports = async (callback) => {
    const accounts = await web3.eth.getAccounts();
    const alice = accounts[1];
    const bob = accounts[2];
    console.log(alice);
//
//Alice le da acceso a bob sobre el salt (certificate) usado para obtener el hash de Name+salt
  const issuer = "0xcBED645B1C1a6254f1149Df51d3591c6B3803007";
  const issuerName = "AcademiaManolo";
  const scVolcado = await SCVolcado.deployed();

  const receiverOtherChain = "0xff77D90D6aA12db33d3Ba50A34fB25401f6e4c4F";
  const port = "transfer";
  const channel = "channel-0";
  const timeoutHeight = 0;

  await scVolcado.setCommParams( receiverOtherChain , port, channel, timeoutHeight,{
    from: alice,
  });

  await scVolcado.addIssuer(issuer, issuerName, {
    from: alice,
  });

  const addIssuer = await scVolcado.getPastEvents("AddIssuer", {
    fromBlock: 0,
  });
  
  console.log(addIssuer);
  callback();
};


