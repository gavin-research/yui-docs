//ALICE DA ACCESO A BOB AL CODIGO 0XF73910...30E ASOCIADO AL HASH SALTEADO DE UN CERTIFICADO
require("web3")
const SCAccess = artifacts.require("SCAccess");

module.exports = async (callback) => {


  const scAccess = await SCAccess.deployed();
  const mirror = await scAccess.getAccessList('0xcBED645B1C1a6254f1149Df51d3591c6B3803007');
  const entidades = await scAccess.getEntidades();
  console.log(entidades);
  callback();
};