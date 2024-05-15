/*const contractAddress = '0xff77D90D6aA12db33d3Ba50A34fB25401f6e4c4F';
const web3 = new Web3('http://127.0.0.1:8645');
const farfe = await fetch('../../../contracts/minitoken/solidity/build/contracts/MiniDelegateB1.json')
const abiJSON = await farfe.json();
*/

// Initialize Web3
window.addEventListener('load', async () => {
    if (window.ethereum) {
        window.web3 = new Web3(window.ethereum);
        try {
            // Request account access if needed
            await window.ethereum.enable();
        } catch (error) {
            console.error(error);
        }
    } else if (window.web3) {
        window.web3 = new Web3(window.web3.currentProvider);
    } else {
        console.error('Non-Ethereum browser detected. You should consider installing MetaMask.');
    }
});

// Function to sign the message
async function signMessage(message) {
    try {
        const accounts = await window.web3.eth.getAccounts();
        const signature = await window.web3.eth.personal.sign(message, accounts[0], "");
        return signature;
    } catch (error) {
        console.error(error);
        return null;
    }
}

// Function to interact with the smart contract
async function grantAccess(signedMessage, message, hashedCode, verifier) {
    try {
        const contractAddress = '0xff77D90D6aA12db33d3Ba50A34fB25401f6e4c4F';
        const farfe = await fetch('../../../contracts/minitoken/solidity/build/contracts/SCAccess.json')
        const contractABI = await farfe.json();

        const contractInstance = new window.web3.eth.Contract(contractABI.abi, contractAddress);
        const accounts = await window.web3.eth.getAccounts();
        
        const r = signedMessage.slice(0, 66);
        const s = "0x" + signedMessage.slice(66, 130);
        const v = parseInt(signedMessage.slice(130, 132), 16);
        console.log({ r, s, v });

        console.log(verifier);
        // Call the modifyAccess function with a true
        //to revoke access call modifyAccess with a false
        const result = await contractInstance.methods.modifyAccess(verifier, message, hashedCode, r, s, v, true).send({ from: accounts[0] });
        console.log(result);
        return result;
    } catch (error) {
        console.error(error);
        return null;
    }
    
}

// Button click event handler
document.getElementById('signButton').addEventListener('click', async () => {
    const message = document.getElementById('message').value;
    const verifier = document.getElementById('verifier').value;
    const hashedCode = web3.utils.sha3(message);
    const signedMessage = await signMessage(hashedCode);
    if (signedMessage) {
        const result = await grantAccess(signedMessage, message, hashedCode, verifier);
        document.getElementById('result').textContent = result ? 'Access granted successfully!' : 'Failed to grant access';
    } else {
        document.getElementById('result').textContent = 'Failed to sign the message';
    }
});

