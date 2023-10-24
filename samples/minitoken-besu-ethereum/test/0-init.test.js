const MiniMessage = artifacts.require("MiniMessage");

contract("MiniMessage", (accounts) => {
  it("Alice should have a cacnea on ibc0", () =>
  MiniMessage.deployed()
      .then((instance) => instance.balanceOf(accounts[1]))
      .then((mensajin) => {
        assert.equal(mensajin.valueOf(), "cacnea", "cacnea wasn't in Alice account");
      }));
});
