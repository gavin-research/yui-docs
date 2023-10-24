const MiniMessage = artifacts.require("MiniMessage");

contract("MiniMessage", (accounts) => {
  it("should sendTransfer el cacnea", async () => {
    const block = await web3.eth.getBlockNumber();
    MiniMessage.deployed()
      .then((instance) =>
        instance.getPastEvents("SendTransfer", {
          filter: { from: accounts[1], to: accounts[2] },
          fromBlock: block,
        })
      )
      .then((evt) => {
        assert.equal(
          evt[0].args.amount.valueOf(),
          "",
          "cacnea wasn't burnt from Alice account"
        );
      });
  });
});
