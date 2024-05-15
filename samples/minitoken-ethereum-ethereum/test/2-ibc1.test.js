const SCAccess = artifacts.require("SCAccess");

contract("SCAccess", (accounts) => {
  it("bob deberia tener el hash del certificado asociado al codigo 0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e", () =>
  SCAccess.deployed()
      .then((instance) => instance.balanceOf(accounts[2]))
      .then((mensajin) => {
        assert.equal(mensajin.valueOf(), "f377e3d8d733de42ec0069766cc8f10b1c5b0b9da03298eea13b196aca6b99e4", "f377e3d8d733de42ec0069766cc8f10b1c5b0b9da03298eea13b196aca6b99e4 wasn't in bob account  via IBC");
      }));
});
