const { ethers, deployments, getNamedAccounts, getUnnamedAccounts } = require('hardhat')
const { expect, assert } = require('chai')
const { addressZero } = require('../../utils/constants')


describe('Blacklist', function() {

   let deployer, users, blacklist
   
   beforeEach(async function() {
        await deployments.fixture(['ids'])
        deployer = (await getNamedAccounts()).deployer
        users = await getUnnamedAccounts()
        const idToken = await ethers.getContract('IDToken', deployer)
        blacklist = await ethers.getContractAt('Blacklist', idToken.address)
    })


    describe('test ownership', function() {
        it('deployer is owner', async function() {
            expect(await blacklist.owner()).to.equal(deployer)
        })
        it('reject ownership transfer to zero address', async function() {
            expect(blacklist.transferOwnership(addressZero)).to.be.rejectedWith('Ownable: new owner is the zero address')
        })
        it('only owner can transfer ownership', async function() {
            expect(blacklist.transferOwnership(users[0], {from: users[1]})).to.be.revertedWith('Ownable: caller is not the owner')
            expect(blacklist.transferOwnership(users[0], {from: users[1]})).to.not.emit('OwnershipTransfer')
        })
        it('owner transfer ownership and emits event', async function() {
            await blacklist.transferOwnership(users[0])
            expect(await blacklist.owner()).to.equal(users[0])
            expect(blacklist.transferOwnership(users[0])).to.emit(blacklist, 'OwnershipTransfer').withArgs(deployer, users[0])
        })
    })

    describe('test renounce function', function() {
        it('only owner can renounce', async function() {
            expect(blacklist.renounceOwnership({from: users[1]})).to.be.revertedWith('Ownable: caller is not the owner')
            expect(blacklist.renounceOwnership()).to.not.emit('OwnershipTransfer')
        })
        it('owner renounce ownership and emits event', async function() {
            await blacklist.renounceOwnership()
            expect(await blacklist.owner()).to.equal(addressZero)
            expect(blacklist.renounceOwnership()).to.emit(blacklist, 'OwnershipTransfer').withArgs(deployer, addressZero)
        })
    })

    describe('test list address function', function() {
        beforeEach(async function() {
            await blacklist.listAddress(users[1])
        })
        it('accessible by owner only', async function() {
            expect(blacklist.listAddress(users[1], {from: users[0]})).to.be.revertedWith('Ownable: caller is not the owner')
        })
        it('reverts if zero address', async function() {
            expect(blacklist.listAddress(addressZero)).to.be.revertedWithCustomError(blacklist, 'Blacklist_ZeroAddress')
        })
        it('reverts if already listed', async function() {
            await blacklist.listAddress(users[1]) 
            expect(blacklist.listAddress(users[1])).to.be.revertedWithCustomError(blacklist, 'Blacklist_Listed')
        })
        it('emits blacklisted event', async function() {
            expect(blacklist.listAddress(users[1])).to.be.emit(blacklist, 'AccountBlacklisted').withArgs(users[1])
        })
        it('returns true if listed', async function() {
            expect(await blacklist.isBlacklisted(users[1])).to.equal(true)
        })
    })
    describe('test removing account from blacklist function', function() {
        beforeEach(async function() {
            await blacklist.listAddress(users[3])
            await blacklist.liftFromList(users[3])
        })
        it('accessible by owner only', async function() {
            expect(blacklist.liftFromList(users[3], {from: users[0]})).to.be.revertedWith('Ownable: caller is not the owner')
        })
        it('reverts if account is not already listed', async function() {
            expect(blacklist.liftFromList(users[1])).to.be.revertedWithCustomError(blacklist, 'Blacklist_NotListed')
        })
        it('emits account unlisted event', async function() {
            expect(blacklist.liftFromList(users[3])).to.be.emit(blacklist, 'AccountUnlisted').withArgs(users[3])
        })
        it('successfully unlisted account', async function() {
            expect(await blacklist.isBlacklisted(users[3])).to.equal(false)
        })
    })
})

