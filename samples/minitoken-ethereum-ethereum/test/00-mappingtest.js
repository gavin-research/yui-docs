//ALICE DA ACCESO A BOB AL CODIGO 0XF73910...30E ASOCIADO AL HASH SALTEADO DE UN CERTIFICADO
require("web3")
const SCAccess = artifacts.require("SCAccess");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  //const alice = accounts[1];
  const alice = accounts[2];
  const scAccess = await SCAccess.deployed();

  // get user nonce
  //const nonce = await scAccess.get_nonce(alice);
  const nonce = await scAccess.getNonce(alice);
  const nonceNumber = nonce.toNumber();

  console.log(nonceNumber);

  const hashedCode = web3.utils.keccak256(nonceNumber.toString());
  console.log({ hashedCode });

  //firma usuario
  const signature = await web3.eth.sign(hashedCode, alice)
  console.log({ signature });

  // split signature
  const r = signature.slice(0, 66);
  const s = "0x" + signature.slice(66, 130);
  const v = parseInt(signature.slice(130, 132), 16);
  console.log({ r, s, v });

  const structFirma = {
    _hashCodeCert: hashedCode,
    _r: r,
    _s: s,
    _v: v
  };
  //IMPORTANTE: 
  //para que la firma vata en getaccesslist hace falta guardar el holder en el contrato
  //hasta que se ejecute el getentidades. De otro modo no se puede asociar getEntidades - holder
  //Para ello hay que guardar el array triple en un mapping holder -> array triple...
  //Y que getEntidades sea getEntidades(address holder, Signature signer) y compare que el
  // signer es el holder solicitado y use holder para acceder al mapping y obtener su array triple
  // correspondiente.
  //Así se soluciona también el problema de si varios usuarios llaman a la vez
  await scAccess.getAccessList(alice);
  const entidades = await scAccess.getEntidades(alice, structFirma);
  console.log(entidades);

  const anadidaVolcado = await scAccess.getHolderofCert("0x333999ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4972727");
  console.log(anadidaVolcado)

  callback();
};