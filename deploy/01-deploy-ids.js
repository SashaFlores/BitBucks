const { ethers, network } = require('hardhat')
const { DEFAULT_ADMIN_ROLE, UPGRADER_ROLE, MANAGER_ROLE } = require('./../utils/constants')

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments;
    const { admin, upgrader, manager } = await getNamedAccounts();
    console.log({namedAccounts: await getNamedAccounts()})

    const networkName = network.name
  
    log(`-----Preparing Contracts for Deployment on ${networkName} -------`)

    const idContract = await deploy('IDToken', {
        contract: 'IDToken',
        from: admin,
        args:[],
        log: true,
        proxy: {
            proxyContract: 'UUPS',
            execute: {
                methodName: '__IDToken_init',
                args: [
                    upgrader, 
                    manager,
                    'http://bafybeihqp5dcnhnspwhs3fqh4tmzweu6nw33iukx6i4sqnv4vwed3zuwc4.ipfs.localhost:8080/{id}.json'
                ]
            }

        },
        waitConfirmations: network.config.blockConfirmations || 1
    })
    const IDToken = await ethers.getContractFactory('IDToken', admin)
    const idToken = await IDToken.attach(idContract.address)
    log(`01- IDToken Proxy deployed at: ${idToken.address}`)
   
    await idToken.grantRole(DEFAULT_ADMIN_ROLE, admin)
    
    const checkAdmin = await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)
    const checkUpgrader = await idToken.hasRole(UPGRADER_ROLE, upgrader)
    const checkManager = await idToken.hasRole(MANAGER_ROLE, manager)
  
    console.log(`Does ${admin} has admin role? ${checkAdmin}`)
    console.log(`Does ${upgrader} has upgrader role? ${checkUpgrader}`)
    console.log(`Does ${manager} has manager role? ${checkManager}`)

}
module.exports.tags = ['all', 'ids']