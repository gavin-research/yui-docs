// BOB ENVIO CORRECTAMENTE UN MENSAJE ENTRE CADENAS
const SCStorage = artifacts.require("SCStorage");

contract("SCStorage", (accounts) => {
  it("Se debe haber volcado 0x2222...78484 con 0x333...72727", async() =>{
    console.log('pedro');
    const scStorage = await SCStorage.deployed();

    const _codigo = await scStorage.getCertificate("0x333999ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4972727"

      , { from: accounts[0] }
    );
    

    assert.equal(_codigo, "0x22222255b3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4978484",
               "0x22222255b3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4978484 wasn't");


  });
});
    /**   */