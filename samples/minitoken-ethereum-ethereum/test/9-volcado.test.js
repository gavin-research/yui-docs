

// BOB EFECTIVAMENTE RECIBE EL HASH SALTEADO F377E3...9E4 ASOCIADO AL CODIGO F73910...30E
// de scstorage 0x333999ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4972727
// de constructor 0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e
const SCData = artifacts.require("SCStorage");

contract("SCData", () => {
  it("Se debe haber volcado 0x2222...78484 con 0x333...72727", () =>
    SCData.deployed()
      .then((instance) => instance.getCertificate("0x333999ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4972727"))
      .then((mensajin) => {
        assert.equal(mensajin.valueOf(), "22222255b3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4978484", "wasn't in bob account  via IBC");
      }));
});



    /**   */