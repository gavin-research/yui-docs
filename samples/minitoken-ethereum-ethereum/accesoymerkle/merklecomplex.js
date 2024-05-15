const crypto = require('crypto');

// Function to calculate the Merkle Root given an array of leaf hashes
function calculateMerkleRoot(leafHashes, mapeado) {
    if (leafHashes.length === 0) {
        return null;
    }
    if (leafHashes.length !== mapeado.length) {
        return null;
    }
    
    var finalHash = '';

    for (let i = 0; i < mapeado.length; i += 1){
        
// 1 con 2, y asñu. si es impar coge ese y el siguiente. los situa un nivel superior en la posicion
// par/2 

        var nivel = leafHashes[i];

        for (let j = 0; j < nivel.length; j +=1){
            
            if (mapeado[i][j] % 2 !== 0){
                // Concatenate and hash the pair of hashes
                const concatenatedHashes = nivel[j] + nivel[j+1];
                finalHash = crypto.createHash('sha256').update(concatenatedHashes).digest('hex');
                levelhash = i+1;
                orderhash = (mapeado[i][j]+1)/2;
                console.log('REEE');
                console.log('Hash for entry ', levelhash, orderhash);
                console.log(finalHash);

                //nivel 0 funciona. subir a niveles mas altos metiendo el resultado en el array j siguiente
                //correspondiente y ordenando segun mapeado y orderhash[][]
            }
        }
    }

    // Iterate over pairs of leaf hashes and hash them together
    
    return finalHash; // Return the root of the Merkle Tree
}

// Example usage - merkle root must be f377e3d8d733de42ec0069766cc8f10b1c5b0b9da03298eea13b196aca6b99e4
const leafHashes = [
    ['ae6a7df7a326a1f5e334e74792f4004b25d1ad603aeaa173334ac544cca0399d','d54012d46c1a498783d0963f712eec03a7d08a08186e9c50902ed6d2866229c9','1ea442a134b2a184bd5d40104401f2a37fbc09ccf3f4bc9da161c6099be3691d','559aead08264d5795d3909718cdd05abd49572e84fe55590eef31a88a08fdffd'],
    ['295e7964b77af889219478f1713f7107deb7940eeb5054c932b2435c6c86c3f4','42929216065e3040bdf1f6446a63ba5834e06e403793569793e62d145d20eab6']
];
const mapeado = [
    [1,2,7,8],
    [2,3]
]

const merkleRoot = calculateMerkleRoot(leafHashes, mapeado);
console.log("Merkle Root:", merkleRoot);
