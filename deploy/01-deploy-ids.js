const { ethers, network } = require('hardhat')
const { assert } = require('chai')
// const { DEFAULT_ADMIN_ROLE, UPGRADER_ROLE, MANAGER_ROLE } = require('./../utils/constants')

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    console.log({namedAccounts: await getNamedAccounts()})

    const networkName = network.name
  
    log(`-----Preparing ID Token Contract for Deployment on ${networkName} -------`)

    const idContract = await deploy('IDToken', {
        contract: 'IDToken',
        from: deployer,
        args:[],
        log: true,
        proxy: {
            proxyContract: 'UUPS',
            execute: {
                methodName: '__IDToken_init',
                args: [
                    'http://bafybeihqp5dcnhnspwhs3fqh4tmzweu6nw33iukx6i4sqnv4vwed3zuwc4.ipfs.localhost:8080/{id}.json'
                ]
            },
            onUpgrade: {
                methodName: 'upgradeTo',
                args:[]
            }

        },
        waitConfirmations: network.config.blockConfirmations || 1
    })
    const IDToken = await ethers.getContractFactory('IDToken', deployer)
    const idToken = await IDToken.attach(idContract.address)
    log(`01- IDToken Proxy deployed at: ${idToken.address}`)
   
    await idToken.connect(deployer)

    assert(await idToken.owner() == deployer)
    

}
module.exports.tags = ['all', 'ids']