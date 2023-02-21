const { ethers } = require('hardhat')

const DEFAULT_ADMIN_ROLE = ethers.constants.HashZero
const UPGRADER_ROLE = ethers.utils.id('UPGRADER_ROLE')      // OR: utils.keccak256(utils.toUtf8Bytes("hello world"))=>32 bytes
const MANAGER_ROLE = ethers.utils.id('MANAGER_ROLE')
const MINTER_ROLE = ethers.utils.id('MINTER_ROLE')
const addressZero = ethers.constants.AddressZero
const availIds = [1, 2, 3, 4, 5]

module.exports = {
    DEFAULT_ADMIN_ROLE,
    UPGRADER_ROLE,
    MANAGER_ROLE,
    MINTER_ROLE,
    addressZero,
    availIds
}