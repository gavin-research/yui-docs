

// BOB EFECTIVAMENTE RECIBE EL HASH SALTEADO F377E3...9E4 ASOCIADO AL CODIGO F73910...30E
// de scstorage 0x333999ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4972727
// de constructor 0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e
const SCAccess = artifacts.require("SCAccess");

contract("SCAccess", () => {
  it("Se debe haber volcado 0x2222...78484 con 0x333...72727", () =>
    SCAccess.deployed()
      .then((instance) => instance.getHolderofCert("0x333999ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd4972727"))
      .then((mensajin) => {
        assert.equal(mensajin.valueOf(), "0x00731540cd6060991D6B9C57CE295998d9bC2faB", "wasn't in bob account  via IBC");
      }));
});



    /**   */