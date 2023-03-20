const { ethers, deployments, getNamedAccounts, getUnnamedAccounts } = require('hardhat')
const { expect } = require('chai')
const { ZERO_ADDRESS } = require('../../utils/constants')
const { developmentChains } = require('../../utils/network-helper')
const { sharedManagerTest } = require('../shared/sharedManager.test.js')
const { sharedBlacklistTest } = require('../shared/sharedBlacklist.test.js')

const newURI = 'sasha.com'

describe('Test ID Token', function() {
    let deployer, users, testId
    beforeEach(async function() {
        await deployments.fixture('testId')
        deployer = (await getNamedAccounts()).deployer
        users = await getUnnamedAccounts()
        testId = await ethers.getContract('TestIDToken', deployer)
    })
    describe('constructor', function() {
        it('parent contract initialized once', async function() {
            expect(testId.__IDToken_init(newURI)).to.be.revertedWith('Initializable: contract is already initialized')
        })
        it('emits ownership transferred event', async function() {
            expect(testId).to.emit(testId, 'OwnershipTransferred').withArgs(ZERO_ADDRESS, deployer)
        })
    
    })
    describe('run shared manager test', function() {
        sharedManagerTest(() => test)
    })

    // TODO: test EOA mint & signature after cryptographic message.

    // TODO: test contract signature

    // TODO: import and run blacklist test
   
})



