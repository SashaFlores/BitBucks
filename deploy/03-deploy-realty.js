const { ethers, network } = require('hardhat')

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy, log, get } = deployments;
    const { deployer } = await getNamedAccounts();
    // console.log({namedAccounts: await getNamedAccounts()})

    const networkName = network.name
    const idToken = await get('IDToken')
    // console.log(`IDToken Contract address is ${idToken.address}`)

    const implementation = await deploy('BitRealty', {
        contract: 'BitRealty',
        args:[],
        log: true,
        from: deployer,
        waitConfirmations: network.config.blockConfirmations || 1
    })

    const deployedImp = await ethers.getContractAt('BitRealty', implementation.address)


    const factory = await deploy('RealtyFactory', {
        contract: 'RealtyFactory',
        from: deployer,
        log: true,
        execute: {
            methodName: '__RealtyFactory_init',
            args:[idToken.address, deployedImp.address]
        },
        waitConfirmations: network.config.blockConfirmations || 1
    })
    
    const deployedFactory = await ethers.getContract('RealtyFactory')

    console.log(`Deployed Implementation Address:  ${deployedImp.address}`)
    console.log(`Deployed Factory Address:  ${factory.address}`)
    console.log(`Deployer: ${deployer}`)
    console.log(`Factory Owner from Factory:  ${await deployedFactory.owner()}`)
    console.log(`Implementation Address from Factory:  ${await deployedFactory.implementation()}`)

}
module.exports.tags = ['all']