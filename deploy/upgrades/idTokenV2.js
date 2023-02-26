const { ethers } = require('hardhat')

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy } = deployments;
    const { upgrader, admin } = await getNamedAccounts();
    console.log({namedAccounts: await getNamedAccounts()})


    const implV2 = await deploy('IDTokenV2', {
        contract: 'IDTokenV2',
        from: upgrader,
        args:[],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    
    const implementationV2 = await ethers.getContractAt('IDTokenV2', implV2.address)

    const idToken = await ethers.getContract('IDToken', admin)

    console.log(`IDTokenV2 Implementation address is ${implementationV2.address}`)

    await idToken.connect(upgrader)

    const secondVersion = await idToken.upgradeTo(implementationV2.address)
    
  

}
module.exports.tags = ['implV2']