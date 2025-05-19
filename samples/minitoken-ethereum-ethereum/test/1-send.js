//BOB SOLICITA ACCESO AL HASH SALTEADO ASOCIADO AL CODIGO 0XF73910...30E
const SCAccess = artifacts.require("SCAccess");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const alice = accounts[1];
  const bob = accounts[2];

  const certificatecode = "0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e";
  const port = "transfer";
  const channel = "channel-0";
  const timeoutHeight = 0;

  const scaccess = await SCAccess.deployed();
//CACNEA CREAR EL STRUCT DE LA FIRMA Y CANAL Y ESO PARA SENDTRANSFER
//SENDTRASFER AHORA NECESITA UNA FIRMA, DE UN TOKEN. GENERAR DICHO TOKEN TAMBIEN PARA VERIFICAR USER

  const params = {
    sourcePort: port,
    sourceChannel: channel,
    timeoutHeight: timeoutHeight
  };

  //-------------------------///
  const nonce = await scaccess.getNonce(bob);
  const nonceNumber = nonce.toNumber();
  
  console.log(nonceNumber);

  const hashedCode = web3.utils.keccak256(nonceNumber.toString());

  console.log({ hashedCode });

  //const signature = await alice.sign(hashedCode);
  const signature = await web3.eth.sign(hashedCode, bob)
  console.log({ signature });

  // split signature
  const r = signature.slice(0, 66);
  const s = "0x" + signature.slice(66, 130);
  const v = parseInt(signature.slice(130, 132), 16);
  console.log({ r, s, v });
  //-------------------------//

  const structFirma = {
    _hashCodeCert: hashedCode,
    _r: r,
    _s: s,
    _v: v
  };


  /*GAS check alg3 in GAVIN*/
    //Initial account balance
    const initial = await web3.eth.getBalance(bob);
    console.log(`Initial: ${initial.toString()}`);

    // Obtain gas used from the receipt
    const receipt = await scaccess.sendTransfer(certificatecode, bob, params, structFirma , {
      from: bob,
    });
    const gasUsed = receipt.receipt.gasUsed;
    console.log(`GasUsed: ${receipt.receipt.gasUsed}`);

    // Obtain gasPrice from the transaction
    const tx = await web3.eth.getTransaction(receipt.tx);
    const gasPrice = tx.gasPrice;
    console.log(`GasPrice: ${tx.gasPrice}`);

    // Final balance
    const final = await web3.eth.getBalance(bob);
    console.log(`Final: ${final.toString()}`);
  /*END GAS CHECK*/
      //cacnea with gas check this next lines will fail due to increased nonce in signature before another interaction:
  // bob solicita acceso para verificar el certificado cheddar
  await scaccess.sendTransfer(certificatecode, bob, params, structFirma , {
    from: bob,
  });

  const sendTransfer = await scaccess.getPastEvents("SendTransfer", {
    fromBlock: 0,
  });
  
  console.log(sendTransfer);

  callback();
};
