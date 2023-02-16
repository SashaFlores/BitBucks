const { deployments, ethers, getNamedAccounts } = require('hardhat')
const { expect, assert } = require('chai')

const addressZero = ethers.constants.AddressZero

describe('Minter Manager Test', function() {

    let minterManager, deployer, manager, minter, other, minter2, manager2, _managers
    //let _managers = []
    beforeEach(async() => {

        await deployments.fixture(['all'])
        minterManager = await ethers.getContract('BitBucks', deployer)
        deployer = (await getNamedAccounts()).deployer
        manager = (await getNamedAccounts()).manager
        minter = (await getNamedAccounts()).minter
        other = (await getNamedAccounts()).other
        minter2 = (await getNamedAccounts()).minter2
        manager2 = (await getNamedAccounts()).manager2
        _managers = new Map()
    })

    describe('initialize deployer as owner', function() {
        it('owner is the deployer', async function() {
            expect(await minterManager.owner()).to.equal(deployer)
        })
        
        it('emits ownership transfer event', async function() {
            expect(minterManager.__BitBucks_init()).to.emit(minterManager, 'OwnershipTransferred')
            .withArgs(addressZero, deployer)
        })

        it('only owner can transfer ownership to non-zero address', async function() {
            expect(minterManager.transferOwnership(addressZero))
            .to.be.rejectedWith('Ownable: new owner is the zero address')
            expect(minterManager.connect(manager).transferOwnership(other))
            .to.be.rejectedWith('Ownable: caller is not the owner')
        })

        it('only owner can renounce', async function() {
            
            await minterManager.renounceOwnership()
            expect(minterManager.renounceOwnership()).to.emit(minterManager, 'OwnershipTransferred')
            .withArgs(deployer, addressZero)
            
            expect(await minterManager.owner()).to.equal(addressZero)

            expect(minterManager.connect(other).renounceOwnership()).to.be.rejectedWith('Ownable: caller is not the owner')
            expect(minterManager.renounceOwnership()).to.not.emit(minterManager, 'OwnershipTransferred')
        })
    })

    describe('assign manager function', function() {
        it('owner assign minter once to a manager and update mapping', async function() {
            await minterManager.assignManager(minter, manager)
            await minterManager.assignManager(minter2, manager)
            expect(await minterManager.isManager(manager, minter)).to.equal(true)
            expect(await minterManager.isManager(manager, minter2)).to.equal(true)
            expect(await minterManager.isMinter(minter)).to.equal(true)
            expect(await minterManager.isMinter(minter2)).to.equal(true)

            // update mapping
            // _managers = new Map([
            //     [manager, [minter, minter2]]
            // ])
            _managers.set(manager, [minter, minter2])
            assert.deepEqual(_managers.get(manager), [minter, minter2])
            assert.strictEqual(_managers.size, 1)

            const index = _managers.get(manager).length
            const managerMinters = _managers.get(manager)
            const minterIndex = managerMinters.indexOf(minter)
            const minter2Index = managerMinters.indexOf(minter2)
        
        
            expect(minterManager.assignManager(minter, manager)).to.emit(minterManager, 'ManagerAssigned')
            .withArgs(manager, minter, minterIndex)

            expect(minterManager.assignManager(minter2, manager)).to.emit(minterManager, 'ManagerAssigned')
            .withArgs(manager, minter2, minter2Index)

            expect(minterManager.assignManager(minter, other)).to.be.revertedWith('Manager: minter exists')
            expect(await minterManager.isManager(other, minter)).to.equal(false)
            expect(await minterManager.isMinter(minter)).to.equal(true)
            expect(minterManager.assignManager(minter, other)).to.not.emit(minterManager, 'ManagerAssigned')

            
        })
        it('reject non owner assign manager', async function() {
            expect(minterManager.connect(manager).assignManager(minter, manager)).to.be.rejectedWith('Ownable: caller is not the owner')
            expect(await minterManager.isManager(manager, minter)).to.equal(false)
            expect(await minterManager.isMinter(minter)).to.equal(false)
            expect(minterManager.assignManager(minter, manager)).to.not.emit(minterManager, 'ManagerAssigned')
        })

        it('reject zero address', async function() {
            expect(minterManager.assignManager(minter, addressZero)).to.be.rejectedWith('Manager: unauthorized zero address')
            expect(minterManager.assignManager(addressZero, manager)).to.be.rejectedWith('Manager: unauthorized zero address')
        })
        it('revert if minter address same as manager', async function() {
            expect(minterManager.assignManager(manager, manager)).to.be.revertedWith('Manager: minter and manager are the same address')
            expect(await minterManager.isManager(manager, manager)).to.equal(false)
            expect(await minterManager.isMinter(minter)).to.equal(false)
            expect(minterManager.assignManager(manager, manager)).to.not.emit(minterManager, 'ManagerAssigned')
        })

    })


})