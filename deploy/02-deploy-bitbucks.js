const {ethers, network } = require('hardhat')

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments;
    const { admin } = await getNamedAccounts();
    console.log({namedAccounts: await getNamedAccounts()})

    const networkName = network.name
    const idToken = await ethers.getContract('IDToken')

    log(`-----Preparing Contracts for Deployment on ${networkName} -------`)

    const stableToken = await deploy('BitBucks', {
        contract: 'BitBucks',
        from: admin,
        args:[],
        log: true,
        proxy: {
            proxyContract: 'UUPS',
            execute: {
                methodName: '__BitBucks_init',
                args: [idToken.address]
            }

        },
        waitConfirmations: network.config.blockConfirmations || 1
    })
    const BitBucks = await ethers.getContractFactory('BitBucks', admin)
    const bitBucks = await BitBucks.attach(stableToken.address)
    log(`001- Proxy deployed to: ${bitBucks.address}`)
   
    await bitBucks.transferOwnership(admin)
    const owner = await bitBucks.owner()

    console.log(`Is ${admin} =  ${owner} ?`)
   
}
module.exports.tags = ['all', 'BitBucks']