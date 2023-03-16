const { ethers } = require('hardhat')


const ZERO_ADDRESS = ethers.constants.AddressZero

// ID Token
const IDS = [1, 2, 3, 4, 5] // available ids 
const DEADLINE = 4233600 // 7 days in secs

module.exports = { ZERO_ADDRESS, IDS, DEADLINE }