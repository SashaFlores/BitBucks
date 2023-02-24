const { deployments, ethers, getNamedAccounts } = require('hardhat')
const { expect } = require('chai')
const { 
    DEFAULT_ADMIN_ROLE, 
    UPGRADER_ROLE, 
    MANAGER_ROLE, 
    MINTER_ROLE,
    addressZero
} = require('../../utils/constants')


describe('admins behavior test', function() {
    let admin, upgrader, manager, other, minter, idToken
 
    beforeEach(async () => {
        
        await deployments.fixture(['ids'])
        admin = (await getNamedAccounts()).admin
        upgrader = (await getNamedAccounts()).upgrader
        manager = (await getNamedAccounts()).manager
        other = (await getNamedAccounts()).other
        minter = (await getNamedAccounts()).minter
        idToken = await ethers.getContract('IDToken', admin)
    })

    describe('admins behavior test', function() {
        it('admin role assigned to admin', async function() {
            expect(await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(true)
            expect(idToken.grantRole(DEFAULT_ADMIN_ROLE, admin)).to.emit(idToken, 'RoleGranted')
            .withArgs(DEFAULT_ADMIN_ROLE, admin, admin)
        })

        it('upgrader role assigned to upgrader', async function() {
            expect(await idToken.hasRole(UPGRADER_ROLE, upgrader)).to.equal(true)
            expect(idToken.grantRole(UPGRADER_ROLE, upgrader)).to.emit(idToken, 'RoleGranted')
            .withArgs(UPGRADER_ROLE, upgrader, admin)
        })

        it('manager role assigned to manager', async function() {
            expect(await idToken.hasRole(MANAGER_ROLE, manager)).to.equal(true)
            expect(idToken.grantRole(MANAGER_ROLE, manager)).to.emit(idToken, 'RoleGranted')
            .withArgs(MANAGER_ROLE, manager, admin)
        })

        it('minter role assigned to minter', async function() {
            await idToken.grantRole(MINTER_ROLE, minter)
            expect(await idToken.hasRole(MINTER_ROLE, minter)).to.equal(true)
            expect(idToken.grantRole(MINTER_ROLE, minter, {from: manager})).to.emit(idToken, 'RoleGranted')
            .withArgs(MINTER_ROLE, minter, manager)
        })

        it('default admin is minter admin', async function() {
            expect(await idToken.getRoleAdmin(MINTER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE)
        })

        it('default admin is its own admin', async function() {
            expect(await idToken.getRoleAdmin(DEFAULT_ADMIN_ROLE)).to.equal(DEFAULT_ADMIN_ROLE)
        })

        it('default admin is upgrader admin', async function() {
            expect(await idToken.getRoleAdmin(UPGRADER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE)
        })

        it('default admin is manager admin', async function() {
            expect(await idToken.getRoleAdmin(MANAGER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE)
        })
    })

    describe('roles granted properly', function() {
        it('reject zero address if used in any role', async function() {
            expect(idToken.grantRole(DEFAULT_ADMIN_ROLE, addressZero))
            .to.be.revertedWithCustomError(idToken, 'IDToken_invalidSignature').withArgs(addressZero)

            expect(idToken.grantRole(UPGRADER_ROLE, addressZero))
            .to.be.revertedWithCustomError(idToken, 'IDToken_invalidSignature').withArgs(addressZero)

            expect(idToken.grantRole(MANAGER_ROLE, addressZero)).to.be.rejectedWith('address zero unauthorized')
            .to.be.revertedWithCustomError(idToken, 'IDToken_invalidSignature').withArgs(addressZero)
        })

        it('revert if non-admin grants role', async function() {
            expect(idToken.grantRole(MANAGER_ROLE, other, {from: upgrader}))
            .to.be.revertedWith('AccessControl: account ${upgrader} is missing role ${DEFAULT_ADMIN_ROLE}')
        })
    })

    describe('revoke roles', function() {
        
        it('admin can revoke minter role', async function() {
            expect(idToken.revokeRole(MINTER_ROLE, minter)).to.emit(idToken, 'RoleRevoked')
            .withArgs(MINTER_ROLE, minter, admin)
            expect(await idToken.hasRole(MINTER_ROLE, minter)).to.equal(false)
        })

        it('admin can revoke manager role', async function() {
            expect(idToken.revokeRole(MANAGER_ROLE, manager)).to.emit(idToken, 'RoleRevoked')
            .withArgs(MANAGER_ROLE, manager, admin)
            expect(await idToken.hasRole(MANAGER_ROLE, manager)).to.equal(false)
        })

        it('admin can revoke upgrader role', async function() {
            expect(idToken.revokeRole(UPGRADER_ROLE, upgrader)).to.emit(idToken, 'RoleRevoked')
            .withArgs(UPGRADER_ROLE, upgrader, admin)
            expect(await idToken.hasRole(UPGRADER_ROLE, upgrader)).to.equal(false)
        })

        it('non admin cannot revoke roles', async function() {
            expect(idToken.revokeRole(UPGRADER_ROLE, upgrader, { from: manager }))
            .to.be.revertedWith('AccessControl: account ${manager} is missing ${DEFAULT_ADMIN_ROLE}')
            expect(await idToken.hasRole(UPGRADER_ROLE, upgrader)).to.equal(true)
        })

        it('only admin can revoke itself', async function() {
            expect(idToken.revokeRole(DEFAULT_ADMIN_ROLE, admin, { from: admin })).to.emit(idToken, 'RoleRevoked')
            .withArgs(DEFAULT_ADMIN_ROLE, admin, admin)
            expect(await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(false)
        })
    }) 

    describe('renounce rules', function() {
        it('upgrader renounce self role with emitting events', async function() {
            expect(idToken.connect(upgrader).renounceRole(UPGRADER_ROLE, upgrader)).to.emit(idToken, 'RoleGranted')
            .withArgs(UPGRADER_ROLE, upgrader, admin)
            .to.emit(idToken, 'RoleRevoked').withArgs(UPGRADER_ROLE, upgrader, upgrader)
        })

        it('revert if renounce other roles', async function() {
            expect(idToken.renounceRole(MINTER_ROLE, minter)).to.be.rejectedWith('AccessControl: can only renounce roles for self')
        })

        it('not emit event', async function() {
            expect(idToken.renounceRole(MINTER_ROLE, minter, {from: minter})).to.not.emit('RoleRevoked')
        })
    })

    describe('pause and unpause', function() {
        it('contract not paused', async function() {
            expect(await idToken.paused()).to.equal(false)
        })

        it('pause fails if not called by admin or upgrader', async function() {
            expect(idToken.connect(manager).pauseOps())
            .to.be.revertedWith('admin or upgrader')

            expect(await idToken.paused()).to.equal(false)
        })

        it('only admin or upgrader can pause', async function(){
            await idToken.pauseOps()
            expect(idToken.connect(admin).pauseOps()).to.emit(idToken, 'Paused').withArgs(admin)
            expect(await idToken.paused()).to.equal(true)
        })

        it('can not pause if already paused', async function() {
            await idToken.pauseOps()
            expect(idToken.pauseOps()).to.be.revertedWith('Pausable: paused')
            expect(await idToken.paused()).to.equal(true)
        })

        it('unpause fails if not called by admin or upgrader', async function() {
            await idToken.pauseOps()
            expect(idToken.connect(manager).unpauseOps()).to.be.revertedWith('admin or upgrader')
            expect(await idToken.paused()).to.equal(true)
        })

        it('unpause called by admin', async function() {
            await idToken.pauseOps()
            expect(idToken.unpauseOps({ from: admin })).to.emit(idToken, 'Unpaused').withArgs(admin)
            expect(await idToken.paused()).to.equal(false)
        })

        it('unpause fails if unpaused', async function() {
            expect(idToken.unpauseOps()).to.be.revertedWith('Pausable: unpause')
        })
    })

})

