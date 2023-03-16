const { ethers, network } = require('hardhat')
const { assert } = require('chai')
const { developmentChains } = require('../../utils/network-helper')


module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const networkName = network.name
  
    if(developmentChains.includes(networkName)) {
        const TestId = await deploy('TestIDToken', {
            contract: 'TestIDToken',
            from: deployer,
            log: true,
            args:[],
            execute: {
                methodName: 'constructor'
            }
        })
        const testId = await ethers.getContract('TestIDToken', deployer)

        assert(await testId.owner() === deployer)
        
        log(`--------------------Tests-2-: Test IDToken Contract at: ${testId.address} on ${networkName} -------------------------`)
    }
}
module.exports.tags = ['testId']