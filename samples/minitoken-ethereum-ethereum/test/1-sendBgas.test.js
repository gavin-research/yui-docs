const ContractB = artifacts.require("SCData");

contract('ContractB', function(accounts) {
  it("Test gas", async () => {
    const contractB = await ContractB.deployed();

    //UPDATE TRANSACTION HASH FROM BLOCKCHAIN B WITH DESTINATION OWNABLEIBCHANDLER HERE
    const hashTransaction = "0xb8e3b3ea79606bb05ded65e31d7ed18688609633052517fa8ad6d2a7c2d943a4";

    const accounts = await web3.eth.getAccounts();
    const alice = accounts[1];

    const port = "transfer";
    const channel = "channel-0";
    const timeoutHeight = 0;

    const data = {
        message: "Alex", 
        sender: alice,
        receiver: alice
    }

    
    
    // Initial balance of the second account
    const initial = await web3.eth.getBalance(alice);
    console.log(`Initial: ${initial.toString()}`);
      
    // Obtain gas used from the receipt
    const receipt = await web3.eth.getTransactionReceipt(hashTransaction);
   // console.log(receipt);
    const gasUsed = receipt.gasUsed;
    console.log(`GasUsed: ${gasUsed}`);

    // Obtain gasPrice from the transaction
    const gasPrice = receipt.effectiveGasPrice;
    console.log(`GasPrice: ${gasPrice}`);

    // Final balance
    const final = await web3.eth.getBalance(accounts[1]);
    console.log(`Final: ${final.toString()}`);
  });
});