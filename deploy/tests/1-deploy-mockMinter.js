const { ethers, network } = require('hardhat')
const { assert } = require('chai')
const { developmentChains } = require('../../utils/network-helper')

module.exports = async({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments;
    const { mocker } = await getNamedAccounts();
    // console.log({namedAccounts: await getNamedAccounts()})

    const networkName = network.name
  
    if(developmentChains.includes(networkName)) {
        const MockMinter = await deploy('MockMinterContract', {
            contract: 'MockMinterContract',
            from: mocker,
            args:[],
            log: true,
            execute: {
                name: 'constructor'
            }
        })
        const mockMinter = await ethers.getContract('MockMinterContract', mocker)
   
        assert(await mockMinter.owner() === mocker)
        
        log(`--------------------Tests-1-: Mock Minter Contract at: ${mockMinter.address} on ${networkName} -------------------------`)
    }
}
module.exports.tags = ['all', 'mockMinter']