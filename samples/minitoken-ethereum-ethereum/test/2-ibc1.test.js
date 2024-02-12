const MiniMessage = artifacts.require("MiniMessage");

contract("MiniMessage", (accounts) => {
  it("should have evolved cacnea into cacturne in alice account on ibc0", () =>
  MiniMessage.deployed()
      .then((instance) => instance.balanceOf(accounts[1]))
      .then((mensajin) => {
        assert.equal(mensajin.valueOf(), "e31822911e580b5ff47d83bebb177a69a78e076baad60a15aac6d4bbb904afc2", "cacturne wasn't in Alice account evolved via Invented-delegatecall");
      }));
});
