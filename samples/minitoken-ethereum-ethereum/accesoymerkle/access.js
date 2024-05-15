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


// Function to interact with the smart contract
async function requestCert(message) {
    try {
        const contractAddress = '0xff77D90D6aA12db33d3Ba50A34fB25401f6e4c4F';
        const farfe = await fetch('../../../contracts/minitoken/solidity/build/contracts/SCAccess.json')
        const contractABI = await farfe.json();

        const contractInstance = new window.web3.eth.Contract(contractABI.abi, contractAddress);
        const accounts = await window.web3.eth.getAccounts();

        const port = "transfer";
        const channel = "channel-0";
        const timeoutHeight = 0;
    
        // Call the grantAccess function
        await contractInstance.methods.sendTransfer(message, accounts[0], port, channel, timeoutHeight).send({
            from: accounts[0],
          });
        
    } catch (error) {
        console.error(error);
        return null;
    }
}

async function sha256(str) {
    const buf = await crypto.subtle.digest("SHA-256", new TextEncoder("utf-8").encode(str));
    return Array.prototype.map.call(new Uint8Array(buf), x=>(('00'+x.toString(16)).slice(-2))).join('');
}


async function checkMerkle(hashes){
    var leafHashes = hashes.split(',').map(function(item) {
        return item.trim(); // Remove any leading or trailing whitespace
    });

    // Log the array of hashes to console
    console.log(leafHashes);
    if (leafHashes.length === 0) {
        return null;
    }
    if (leafHashes.length === 1) {
        return leafHashes[0];
    }

    var finalHash = '';
    // Iterate and hash together
    for (let i = 0; i < leafHashes.length; i += 1) {
        console.log('aaa', leafHashes.length, i );
        if(i == 0){
            finalHash = leafHashes[i];
            console.log(finalHash);
        }else{
            const hash1 = leafHashes[i];
            // Concatenate and hash the pair of hashes
            const concatenatedHashes = finalHash + hash1;
            finalHash = await sha256(concatenatedHashes);
            console.log(concatenatedHashes, finalHash);
        }  
    }

    try{
        const contractAddress = '0xff77D90D6aA12db33d3Ba50A34fB25401f6e4c4F';
        const farfe = await fetch('../../../contracts/minitoken/solidity/build/contracts/SCAccess.json')
        const contractABI = await farfe.json();

        const contractInstance = new window.web3.eth.Contract(contractABI.abi, contractAddress);
        const accounts = await window.web3.eth.getAccounts();

        const receivedHash = await contractInstance.methods.balanceOf(accounts[0]).call({
            from: accounts[0],
          });
          
        if (finalHash === receivedHash) {
            document.getElementById('merklevalid').textContent = 'Values match. Correct!';
            return finalHash; // Return the root of the Merkle Tree
        } else {
            document.getElementById('merklevalid').textContent = 'Values do not match. Incorrect!';
            return 'NO CORRECTOOOO'; // Return the root of the Merkle Tree
        }

    }catch (error) {
        console.error(error);
        return null;
    }
    
}

// Button click event handler
document.getElementById('sendButton').addEventListener('click', async () => {
    const message = document.getElementById('message').value;
        const result = await requestCert(message);
        document.getElementById('result').textContent = result;
});

// Button click event handler
document.getElementById('checkButton').addEventListener('click', async () => {
    const hashes = document.getElementById('hashes').value;
        const result = await checkMerkle(hashes);
        document.getElementById('merklevalid').textContent = result;
});

