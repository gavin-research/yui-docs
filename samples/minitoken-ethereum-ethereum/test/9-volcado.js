require("web3")
const SCVolcado = artifacts.require("SCVolcado");
module.exports = async (callback) => {
    const accounts = await web3.eth.getAccounts();
    const alice = accounts[1];
    const bob = accounts[2];
//
//Alice le da acceso a bob sobre el salt (certificate) usado para obtener el hash de Name+salt
  const certificado = "0x22222255b3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4978484";
  const certificatecode = "0x333999ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4972727";
  const entity = bob;
  const scVolcado = await SCVolcado.deployed();

  const receiverOtherChain = "0xff77D90D6aA12db33d3Ba50A34fB25401f6e4c4F";
  const port = "transfer";
  const channel = "channel-0";
  const timeoutHeight = 0;

  await scVolcado.setCommParams( receiverOtherChain , port, channel, timeoutHeight,{
    from: alice,
  });

  await scVolcado.addCertificate(certificado, certificatecode, entity, {
    from: alice,
  });

  const addCertificate = await scVolcado.getPastEvents("AddCertificate", {
    fromBlock: 0,
  });
  
  console.log(addCertificate);
  callback();
};


