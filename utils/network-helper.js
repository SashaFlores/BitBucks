const { network } = require('hardhat')

const developmentChains = ['hardhat', 'localDev']

const moveTime = async(seconds) => {
    await network.provider.send('evm_increaseTime', [seconds])
    // await hre.ethers.provider.send('evm_increaseTime', [7 * 24 * 60 * 60]);
    console.log(`Time Moved Forward ${seconds} seconds`)
}

const moveBlocks = async(block) => {
    for(let i =0; i < block; i++) {
        await network.provider.request({
            method: 'evm_mine',
            params: []
        })
    }
    console.log(`Moved Forward ${block} blocks`)
}

module.exports = { developmentChains, moveTime, moveBlocks }