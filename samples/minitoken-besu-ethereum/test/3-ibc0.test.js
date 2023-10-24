const MiniMessage = artifacts.require("MiniMessage");

contract("MiniMessage", (accounts) => {
  it("should have no cacnea in alice account on ibc0", () =>
  MiniMessage.deployed()
      .then((instance) => instance.balanceOf(accounts[1]))
      .then((mensajin) => {
        assert.equal(mensajin.valueOf(), "", "cacnea sa kedao in Alice account");
      }));
});
