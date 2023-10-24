const MiniMessage = artifacts.require("MiniMessage");

contract("MiniMessage", (accounts) => {
  it("should put cacnea in bob account on ibc1", () =>
  MiniMessage.deployed()
      .then((instance) => instance.balanceOf(accounts[2]))
      .then((mensajin) => {
        assert.equal(mensajin.valueOf(), "cacnea", "cacnea wasn't in Bob account");
      }));
});
