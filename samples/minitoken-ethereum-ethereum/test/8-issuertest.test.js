// BOB ENVIO CORRECTAMENTE UN MENSAJE ENTRE CADENAS
const SCAccess = artifacts.require("SCAccess");

contract("SCAccess", () => {
  it("Se debe haber incluido Academia Manolo", async() =>{
    console.log('CACNEA REVISA SI ESTAS USANDO LA CADENA IBC 0');
    const sCAccess = await SCAccess.deployed();

    const _issuerName = await sCAccess.getIssuer("0x7591b2CC2996BF882F627b8B69081d1690D5eF40"

      
    );
    

    assert.equal(_issuerName, "AcademiaManolo",
               "Academia Manolo no esta en el contrato");

  });
});
    /**   */