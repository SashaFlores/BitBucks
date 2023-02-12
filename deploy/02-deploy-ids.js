const {ethers, network } = require('hardhat')

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments;
    const { admin, upgrader } = await getNamedAccounts();
    console.log({namedAccounts: await getNamedAccounts()})

    const networkName = network.name
    const DEFAULT_ADMIN_ROLE = ethers.utils.id('DEFAULT_ADMIN_ROLE')
    const UPGRADER_ROLE = ethers.utils.id('UPGRADER_ROLE')

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
                args: [upgrader, 'http://bafybeihqp5dcnhnspwhs3fqh4tmzweu6nw33iukx6i4sqnv4vwed3zuwc4.ipfs.localhost:8080/{id}.json']
            }

        },
        waitConfirmations: network.config.blockConfirmations || 1
    })
    const IDToken = await ethers.getContractFactory('IDToken', admin)
    const idToken = await IDToken.attach(idContract.address)
    log(`001- Proxy deployed to: ${idToken.address}`)
   
    const symbol = await idToken.symbol()
    log(`symbol is ${symbol}`)

    await idToken.grantRole(DEFAULT_ADMIN_ROLE, admin)
    const checkAdmin = await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)
    const checkUpgrader = await idToken.hasRole(UPGRADER_ROLE, upgrader)

    console.log(`Does ${admin} has admin role? ${checkAdmin}`)
    console.log(`Does ${upgrader} has upgrader role? ${checkUpgrader}`)
}
module.exports.tags = ['all', 'IDToken']