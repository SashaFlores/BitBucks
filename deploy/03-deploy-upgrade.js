const { ethers, network } = require('hardhat')
const { UPGRADER_ROLE } = require('./../utils/constants')

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments;
    const { upgrader } = await getNamedAccounts();
    console.log({namedAccounts: await getNamedAccounts()})

    const networkName = network.name
  
    log(`-----Preparing Contracts for Deployment on ${networkName} -------`)

    const testUpgrade = await deploy('Version 2', {
        contract: 'IDTokenV2',
        from: upgrader,
        args:[],
        log: true,
        proxy: {
            proxyContract: 'UUPS',
            execute: {
                methodName: '__IDTokenV2_init',
                args: [
                    'http://sashaflores/{id}.json'
                ]
            }

        },
        waitConfirmations: network.config.blockConfirmations || 1
    })
    const IDTokenV2 = await ethers.getContractFactory('IDTokenV2', upgrader)
    const versionTwo = await IDTokenV2.attach(testUpgrade.address)
    log(`01- IDToken v2 Proxy deployed at: ${versionTwo.address}`)
   
    await versionTwo.connect(upgrader)
    

    const checkVersion = await versionTwo.version()
    console.log(`check upgrade ${checkVersion}`)
  

}
module.exports.tags = ['all']