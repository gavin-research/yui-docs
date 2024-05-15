const crypto = require('crypto');

// Function to calculate the Merkle Root given an array of leaf hashes
function calculateMerkleRoot(leafHashes) {
    if (leafHashes.length === 0) {
        return null;
    }
    if (leafHashes.length === 1) {
        return leafHashes[0];
    }

    var finalHash = '';
    // Iterate over pairs of leaf hashes and hash them together
    for (let i = 0; i < leafHashes.length; i += 1) {
        console.log('aaa', leafHashes.length, i );
        if(i == 0){
            finalHash = leafHashes[i];
            console.log(finalHash);
        }else{
            const hash1 = leafHashes[i];
            // Concatenate and hash the pair of hashes
            const concatenatedHashes = finalHash + hash1;
            finalHash = crypto.createHash('sha256').update(concatenatedHashes).digest('hex');
        }  
    }
    return finalHash; // Return the root of the Merkle Tree
}

// Example usage - merkle root must be f377e3d8d733de42ec0069766cc8f10b1c5b0b9da03298eea13b196aca6b99e4
const leafHashes = [
    "8a1dde5a8e98b0745f1dc31d156d19f5c717bc2fbedae95586a45bf2d52db591",
    "8eeef99d2f9ec038818c12eb5972964cf325a43b2ab40bf5c1b5742d39d9d16d",
    "13e28e16f2eb745430a3585c6db914f13856d2942659acdab952f4d391eabacf"
];

const merkleRoot = calculateMerkleRoot(leafHashes);
console.log("Merkle Root:", merkleRoot);
