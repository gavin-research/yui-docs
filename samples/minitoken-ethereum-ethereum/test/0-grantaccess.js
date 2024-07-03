//ALICE DA ACCESO A BOB AL CODIGO 0XF73910...30E ASOCIADO AL HASH SALTEADO DE UN CERTIFICADO
require("web3")
const SCAccess = artifacts.require("SCAccess");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const alice = accounts[1];
  const bob = accounts[2];

  //Alice le da acceso a bob sobre el salt (certificate) usado para obtener el hash de Name+salt
  const certificatecode = "0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e";
  const entity = bob;

  const hashedCode = web3.utils.sha3(certificatecode);
  console.log({ hashedCode });

  //const signature = await alice.sign(hashedCode);
  const signature = await web3.eth.sign(hashedCode, alice)
  console.log({ signature });

  // split signature
  const r = signature.slice(0, 66);
  const s = "0x" + signature.slice(66, 130);
  const v = parseInt(signature.slice(130, 132), 16);
  console.log({ r, s, v });

//CACNEA CREAR EL STRUCT DE LA FIRMA PARA MODIFY ACCESS
  const scAccess = await SCAccess.deployed();
  const structFirma = [hashedCode, r, s, v];

  await scAccess.modifyAccess(entity, certificatecode, structFirma, 1, {
    from: alice,
  });

  
  const grantAccess = await scAccess.getPastEvents("ModifyAccess", {
    fromBlock: 0,
  });
  
  console.log(grantAccess);
  callback();
};
