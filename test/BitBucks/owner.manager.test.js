const { deployments, ethers, getNamedAccounts } = require('hardhat')
const { expect } = require('chai')

const addressZero = ethers.constants.AddressZero

describe('Minter Manager Test', function() {

    let minterManager, deployer, manager, minter, other

    beforeEach(async() => {

        await deployments.fixture(['all'])
        minterManager = await ethers.getContract('BitBucks', deployer)
        deployer = (await getNamedAccounts()).deployer
        manager = (await getNamedAccounts()).manager
        minter = (await getNamedAccounts()).minter
        other = (await getNamedAccounts()).other
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


})