const { deployments, ethers, getNamedAccounts } = require('hardhat')
const { expect, assert } = require('chai')
const { developmentChains } = require('../../network-helper')

const addressZero = ethers.constants.AddressZero

!developmentChains.includes(network.name)
? describe.skip
: describe('Minter Manager Test', function() {

    let minterManager, deployer, manager, minter, other, minter2, manager2, _managers, minterIndex, minter2Index, managerMinters
   
    beforeEach(async() => {

        await deployments.fixture(['managerMock'])
        minterManager = await ethers.getContract('MinterManagerMock', deployer)
        deployer = (await getNamedAccounts()).deployer
        //await minterManager.connect(deployer)
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
            expect(minterManager.__MinterManagerMock_init()).to.emit(minterManager, 'OwnershipTransferred')
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

    describe('assign manager function test', function() {
        it('owner assign minter to manager and update mapping', async function() {
            await minterManager.assignManager(minter, manager)
            await minterManager.assignManager(minter2, manager)
            expect(await minterManager.isManager(manager, minter)).to.equal(true)
            expect(await minterManager.isManager(manager, minter2)).to.equal(true)
            expect(await minterManager.isMinter(minter)).to.equal(true)
            expect(await minterManager.isMinter(minter2)).to.equal(true)

            // create the mapping
            // const _managers = new Map()

            // check if `manager` already exists
            if (_managers.has(manager)) {
                _managers.get(manager).push(minter, minter2)
            } else {
                // update mapping with new assignees
                _managers.set(manager, [minter, minter2])
            }

            assert.deepEqual(_managers.get(manager), [minter, minter2])
            assert.strictEqual(_managers.size, 1)

            managerArrLength = _managers.get(manager).length
            // console.log(managerArrLength)
            managerMinters = _managers.get(manager)
            minterIndex = managerMinters.indexOf(minter)
            minter2Index = managerMinters.indexOf(minter2)
        
            expect(minterManager.assignManager(minter, manager)).to.emit(minterManager, 'ManagerAssigned')
            .withArgs(manager, minter, minterIndex)
            expect(minterManager.assignManager(minter2, manager)).to.emit(minterManager, 'ManagerAssigned')
            .withArgs(manager, minter2, minter2Index)   

            expect(await minterManager.managerMintersCount(manager)).to.equal(managerArrLength)
            
            expect(await minterManager.minterAddress(minter, minterIndex)).to.equal(minter)
            expect(await minterManager.minterAddress(minter2, minter2Index)).to.equal(minter2)

            // expect(await minterManager.allManagerMinters(manager)).to.equal(managerMinters)
            
            // revert if minter exists
            expect(minterManager.assignManager(minter, manager2)).to.be.revertedWith('Manager: minter exists')
            expect(await minterManager.isManager(manager2, minter)).to.equal(false)
            expect(await minterManager.isMinter(minter)).to.equal(true)
            expect(minterManager.assignManager(minter, manager2)).to.not.emit(minterManager, 'ManagerAssigned')
        })
     
        it('reject non owner assign member', async function() {
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
            expect(await minterManager.isMinter(manager)).to.equal(false)
            expect(minterManager.assignManager(manager, manager)).to.not.emit(minterManager, 'ManagerAssigned')
        })
    })

    describe('change manager function test', function() {
        (beforeEach(async() => {
            await minterManager.assignManager(minter, manager)
            await minterManager.assignManager(minter2, manager)
            _managers.set(manager, [minter, minter2])
            managerMinters = _managers.get(manager)
            minterIndex = managerMinters.indexOf(minter)
            minter2Index = managerMinters.indexOf(minter2)
        }))
        it('minter and manager previously assigned', async function() {
           expect(await minterManager.isManager(manager, minter)).to.equal(true)
           expect(await minterManager.isManager(manager, minter2)).to.equal(true)
        })
      
        it('change previous manager with new non zero manager and update mapping', async function() {
            await minterManager.changeManager(manager2, manager, minter2, minter2Index)
            
            // initialize the map object `_managers`
            //let _managers = new Map()
            // update map with first key-value pair of `manager` 
            // and its array of `minter`& `minter2`
            
            assert.deepEqual(_managers.get(manager), [minter, minter2])
            assert.strictEqual(_managers.size, 1)
  
            // check if `manager2` key already exists
            if(_managers.has(manager2)) {
                _managers.get(manager2).push(minter2)
            } else {
                // if not then set a new key-value pair
                _managers.set(manager2, [minter2])
            }
            // get array of minters assigned to `manager`
            managerMinters = _managers.get(manager)
            // console.log(`${managerMinters}`)

           
            for(let i = 0; i < managerMinters.length; i++) {
                if(managerMinters[i] == minter) {
                    minterIndex = i
                }
                if(managerMinters[i] == minter2) {
                    minter2Index = i
                }
            }
            // console.log(_managers)

            // delete `minter2` from `manager` at its index `minter2Index
            managerMinters.splice(minter2Index, 1)
            assert.deepEqual(_managers.get(manager), [minter])
            assert.deepEqual(_managers.get(manager2), [minter2])
            assert.strictEqual(_managers.size, 2)
        
            // reject address zero as `newManager`
            expect(minterManager.changeManager(addressZero, manager2, minter2, minter2Index))
            .to.be.rejectedWith('Manager: unauthorized zero address')
            expect(minterManager.changeManager(addressZero, manager2, minter2, minter2Index)).to.not.emit(minterManager, 'ManagerChanged')
            
            expect(minterManager.changeManager(manager2, other, minter2, minter2Index))
            .to.be.rejectedWith('Manager: not the right manager')

            expect(minterManager.changeManager(manager2, manager, minter2, minter2Index)).to.emit(minterManager, 'ManagerChanged')
            .withArgs(manager, manager2)
            expect(await minterManager.isManager(manager2, minter2)).to.equal(true)
            expect(await minterManager.isManager(manager, minter)).to.equal(true)
            expect(await minterManager.isManager(manager, minter2)).to.equal(false)
     
            const managerArrLength = managerMinters.length
            const manager2Minters = _managers.get(manager2).length
            expect(await minterManager.managerMintersCount(manager)).to.equal(managerArrLength)
            expect(await minterManager.managerMintersCount(manager2)).to.equal(manager2Minters)


      


        })


    })


})