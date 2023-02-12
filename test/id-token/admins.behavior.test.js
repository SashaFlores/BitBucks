const { deployments, ethers, getNamedAccounts } = require('hardhat')
const { expect } = require('chai')


const addressZero = ethers.constants.AddressZero
const DEFAULT_ADMIN_ROLE = ethers.constants.HashZero
const UPGRADER_ROLE = ethers.utils.id('UPGRADER_ROLE') // OR: utils.keccak256(utils.toUtf8Bytes("hello world"))=>32 bytes
const MINTER_ROLE = ethers.utils.id('MINTER_ROLE')

const availIds = [1, 2, 3, 4, 5]

describe('admins behavior test', function() {
    let admin, upgrader, other, minter, idToken
 
    beforeEach(async () => {
        
        await deployments.fixture(['IDToken'])
        admin = (await getNamedAccounts()).admin
        upgrader = (await getNamedAccounts()).upgrader
        other = (await getNamedAccounts()).other
        minter = (await getNamedAccounts()).minter
        idToken = await ethers.getContract('IDToken', admin)
        //console.log(`ID Token Address ${idToken.address}`)
    })

    describe('check admins', function() {
        it('default admin role assigned to admin', async() => {
            expect(await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(true)
        })

        it('upgrader role assigned to upgrader', async() => {
            expect(await idToken.hasRole(UPGRADER_ROLE, upgrader)).to.equal(true)
        })

        it('default admin is its own admin', async() => {
            expect(await idToken.getRoleAdmin(DEFAULT_ADMIN_ROLE)).to.equal(DEFAULT_ADMIN_ROLE)
        })

        it('default admin is upgrader admin', async() => {
            expect(await idToken.getRoleAdmin(UPGRADER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE)
        })

        it('default admin is minter admin', async() => {
            expect(await idToken.getRoleAdmin(MINTER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE)
        })
    })

    describe('roles granted properly', function() {
        beforeEach(async() => {
            await idToken.grantMinterRole(minter, [availIds[0]])
        })

         it('admin grants all roles', async() => {
            expect(await idToken.hasRole(MINTER_ROLE, minter)).to.equal(true)
            expect(idToken.grantRole(DEFAULT_ADMIN_ROLE, admin)).to.emit(idToken, 'RoleGranted')
            .withArgs(DEFAULT_ADMIN_ROLE, admin, admin)
            expect(idToken.grantRole(UPGRADER_ROLE, upgrader)).to.emit(idToken, 'RoleGranted')
            .withArgs(UPGRADER_ROLE, upgrader, admin)
            expect(idToken.grantRole(MINTER_ROLE, minter)).to.emit(idToken, 'RoleGranted')
            .withArgs(MINTER_ROLE, minter, admin)
            expect(idToken.grantMinterRole(minter, [availIds[0]])).to.emit(idToken, 'MinterSet')
            .withArgs(minter, [availIds[0]])
        })

        it('reject zero address if used in any role', async() => {
            expect(idToken.grantRole(DEFAULT_ADMIN_ROLE, addressZero)).to.be.rejectedWith('address zero unauthorized')
            expect(idToken.grantRole(UPGRADER_ROLE, addressZero)).to.be.rejectedWith('address zero unauthorized')
            expect(idToken.grantRole(MINTER_ROLE, addressZero)).to.be.rejectedWith('address zero unauthorized')
        })

        it('revert if non-admin grants role', async() => {
            expect(idToken.grantRole(MINTER_ROLE, minter, { from: upgrader }))
            .to.be.revertedWith('AccessControl: account ${upgrader} is missing role ${DEFAULT_ADMIN_ROLE}')
        })
    })

    describe('pause and unpause', function() {
        it('contract not paused', async() => {
            expect(await idToken.paused()).to.equal(false)
        })

        it('pause fails if not called by admin or upgrader', async() => {
            expect(idToken.connect(other).pauseOps()).to.be.revertedWith('missing role')
            expect(await idToken.paused()).to.equal(false)
        })

        it('admin or upgrader only can pause', async() =>{
            await idToken.pauseOps()
            expect(idToken.connect(upgrader).pauseOps()).to.emit(idToken, 'Paused').withArgs(upgrader)
            expect(await idToken.paused()).to.equal(true)
        })

        it('can not pause if already paused', async() => {
            await idToken.pauseOps()
            expect(idToken.pauseOps()).to.be.revertedWith('Pausable: paused')
            expect(await idToken.paused()).to.equal(true)
        })

        it('unpause fails if not called by admin or upgrader', async() => {
            await idToken.pauseOps()
            expect(idToken.connect(other).unpauseOps()).to.be.revertedWith('missing role')
            expect(await idToken.paused()).to.equal(true)
        })

        it('unpause called by admins', async() => {
            await idToken.pauseOps()
            expect(idToken.unpauseOps({ from: admin })).to.emit(idToken, 'Unpaused').withArgs(admin)
            expect(await idToken.paused()).to.equal(false)
        })

        it('unpause fails if unpaused', async() => {
            expect(idToken.unpauseOps()).to.be.revertedWith('Pausable: unpause')
        })
    })

    describe('revoke roles', function() {
        it('only admin can revoke roles', async function() {
            expect(await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(true)

            expect(idToken.revokeRole(MINTER_ROLE, minter)).to.emit(idToken, 'RoleRevoked')
            .withArgs(MINTER_ROLE, minter, admin)
            expect(await idToken.hasRole(MINTER_ROLE, minter)).to.equal(false)

            expect(idToken.revokeRole(UPGRADER_ROLE, upgrader, { from: other }))
            .to.be.revertedWith('AccessControl: account ${other} is missing ${DEFAULT_ADMIN_ROLE}')
            expect(await idToken.hasRole(UPGRADER_ROLE, upgrader)).to.equal(true)

            expect(idToken.revokeRole(DEFAULT_ADMIN_ROLE, admin)).to.emit(idToken, 'RoleRevoked')
            .withArgs(DEFAULT_ADMIN_ROLE, admin, admin)
            expect(await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(false)
        })
    }) 

    // renounce test


})

