const SCAccess = artifacts.require("SCAccess");

contract("MiniMessage", (accounts) => {
  it("bob debe haber enviado 0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e por el IBC", async () => {
    const block = await web3.eth.getBlockNumber();
    SCAccess.deployed()
      .then((instance) =>
        instance.getPastEvents("SendTransfer", {
          fromBlock: block,
        })
      )
      .then((evt) => {
        assert.equal(
          evt[0].args.amount.valueOf(),
          "",
          "0xf73910ddb3e35a2db69926e7d422df45a52751d09bc99ceaed08ed2dd497930e no ha sido enviado desde bob a traves del ibc"
        );
      });
  });
});
