require('dotenv').config();
const { network } = require('hardhat')

const developmentChains = ['hardhat', 'localDev']

const moveTime = async(seconds) => {
    await network.provider.send('evm_increaseTime', [seconds])
    console.log(`Move Time Forward ${seconds} seconds`)
}



    

module.exports = { developmentChains, moveTime }