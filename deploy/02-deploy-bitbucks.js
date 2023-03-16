const { ethers, network } = require('hardhat')

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy, log, get } = deployments;
    const { deployer } = await getNamedAccounts();
    // console.log({namedAccounts: await getNamedAccounts()})

    const networkName = network.name
    const idToken = await get('IDToken')
    // console.log(`IDToken Contract address is ${idToken.address}`)

    // log(`-----Preparing BitBucks Contract for Deployment on ${networkName} -------`)

    const stableToken = await deploy('BitBucks', {
        contract: 'BitBucks',
        from: deployer,
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
    const BitBucks = await ethers.getContractFactory('BitBucks', deployer)
    const bitBucks = await BitBucks.attach(stableToken.address)

    await bitBucks.connect(deployer)
    const contractOwner = await bitBucks.owner()
    // console.log(`Deployer: ${deployer}`)
    // console.log(`Owner:  ${contractOwner}`)
    log(`----------------- 02- BitBucks Proxy deployed at: ${bitBucks.address} on ${networkName} ---------------------------`)
   
}
module.exports.tags = ['all', 'bit']