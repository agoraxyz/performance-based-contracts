// WARNING: DO NOT DELETE THIS FILE
// This file was auto-generated by the Witnet compiler, any manual changes will be overwritten except
// each contracts' constructor arguments (you can freely edit those and the compiler will respect them).

const WitnetParserLib = artifacts.require("WitnetParserLib")
const WitnetProxy = artifacts.require("WitnetProxy")
const Monetizer = artifacts.require("Monetizer")

module.exports = async function (deployer) {
  await deployer.link(WitnetParserLib, [Monetizer])
  await deployer.deploy(Monetizer, WitnetProxy.address)
  const monetizer = await Monetizer.deployed()
  await monetizer.initialize()
}
