const { deployments, ethers, getNamedAccounts } = require('hardhat')
const { expect } = require('chai')
const { 
    DEFAULT_ADMIN_ROLE, 
    UPGRADER_ROLE, 
    MANAGER_ROLE, 
    MINTER_ROLE,
    addressZero, 
    availIds 
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

    describe('check admins', function() {
        it('default admin role assigned to admin', async function() {
            expect(await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(true)
        })

        it('upgrader role assigned to upgrader', async function() {
            expect(await idToken.hasRole(UPGRADER_ROLE, upgrader)).to.equal(true)
        })

        it('manager role assigned to manager', async function() {
            expect(await idToken.hasRole(MANAGER_ROLE, manager)).to.equal(true)
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

        it('default admin is minter admin', async function() {
            expect(await idToken.getRoleAdmin(MINTER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE)
        })

        it('admin is owner', async function() {
            expect(await idToken.owner()).to.equal(admin)
        })
    })

    describe('roles granted properly', function() {
        beforeEach(async() => {
            await idToken.grantMinterRole(minter, [availIds[0]], 7)
        })

        it('admin grants all roles', async function() {
            expect(await idToken.hasRole(MINTER_ROLE, minter)).to.equal(true)
            expect(idToken.grantRole(DEFAULT_ADMIN_ROLE, admin)).to.emit(idToken, 'RoleGranted')
            .withArgs(DEFAULT_ADMIN_ROLE, admin, admin)

            expect(idToken.grantRole(UPGRADER_ROLE, upgrader)).to.emit(idToken, 'RoleGranted')
            .withArgs(UPGRADER_ROLE, upgrader, admin)

            expect(idToken.grantRole(MINTER_ROLE, minter)).to.emit(idToken, 'RoleGranted')
            .withArgs(MINTER_ROLE, minter, admin)

            expect(idToken.grantRole(MANAGER_ROLE, manager)).to.emit(idToken, 'RoleGranted')
            .withArgs(MANAGER_ROLE, manager, admin)

            expect(idToken.grantMinterRole(minter, [availIds[0]])).to.emit(idToken, 'MinterSet')
            .withArgs(minter, [availIds[0]])
        })

        // it('reject zero address if used in any role', async function() {
        //     expect(idToken.grantRole(DEFAULT_ADMIN_ROLE, addressZero)).to.be.rejectedWith('address zero unauthorized')
        //     expect(idToken.grantRole(UPGRADER_ROLE, addressZero)).to.be.rejectedWith('address zero unauthorized')
        //     expect(idToken.grantRole(MINTER_ROLE, addressZero)).to.be.rejectedWith('address zero unauthorized')
        //     expect(idToken.grantRole(MANAGER_ROLE, addressZero)).to.be.rejectedWith('address zero unauthorized')
        // })

        // it('only minter with minter role can mint and burn', async function() {
        //     expect(await idToken.hasRole(MINTER_ROLE, minter)).to.equal(true)
            
        //     expect(idToken.connect(minter).mint(availIds[0])).to.emit(idToken, 'TransferSingle')
        //     .withArgs(minter, addressZero, minter, availIds[0], 1)

        //     expect(idToken.connect(minter).burn(availIds[0])).to.emit(idToken, 'TransferSingle')
        //     .withArgs(minter, minter, addressZero, availIds[0], 1)

        //     expect(idToken.connect(other).mint(availIds[0]))
        //     .to.be.revertedWith('AccessControl: account ${other} is missing role ${MINTER_ROLE}')
        // })

        // it('revert if non-manager grants role', async function() {
        //     expect(idToken.grantMinterRole(other, availIds[1], { from: upgrader }))
        //     .to.be.revertedWith('AccessControl: account ${upgrader} is missing role ${MANAGER_ROLE}')
        // })
    })

    // describe('pause and unpause', function() {
    //     it('contract not paused', async function() {
    //         expect(await idToken.paused()).to.equal(false)
    //     })

    //     it('pause fails if not called by admin or upgrader', async function() {
    //         expect(idToken.connect(other).pauseOps()).to.be.revertedWith('missing role')
    //         expect(await idToken.paused()).to.equal(false)
    //     })

    //     it('admin or upgrader can pause and all ops are paused', async function(){
    //         await idToken.pauseOps()
    //         expect(idToken.connect(upgrader).pauseOps()).to.emit(idToken, 'Paused').withArgs(upgrader)
    //         expect(await idToken.paused()).to.equal(true)

    //         expect(idToken.updateURI('https://sasha.info')).to.be.rejectedWith('Pausable: paused')

    //         expect(idToken.grantMinterRole(other, availIds[2])).to.be.revertedWith('Pausable: paused')
    //     })

    //     it('can not pause if already paused', async function() {
    //         await idToken.pauseOps()
    //         expect(idToken.pauseOps()).to.be.revertedWith('Pausable: paused')
    //         expect(await idToken.paused()).to.equal(true)
    //     })

    //     it('unpause fails if not called by admin or upgrader', async function() {
    //         await idToken.pauseOps()
    //         expect(idToken.connect(other).unpauseOps()).to.be.revertedWith('missing role')
    //         expect(await idToken.paused()).to.equal(true)
    //     })

    //     it('unpause called by admins', async function() {
    //         await idToken.pauseOps()
    //         expect(idToken.unpauseOps({ from: admin })).to.emit(idToken, 'Unpaused').withArgs(admin)
    //         expect(await idToken.paused()).to.equal(false)
    //     })

    //     it('unpause fails if unpaused', async function() {
    //         expect(idToken.unpauseOps()).to.be.revertedWith('Pausable: unpause')
    //     })
    // })

    // describe('revoke roles', function() {
    //     it('only admin can revoke roles', async function() {
    //         expect(await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(true)

    //         expect(idToken.revokeRole(MINTER_ROLE, minter)).to.emit(idToken, 'RoleRevoked')
    //         .withArgs(MINTER_ROLE, minter, admin)
    //         expect(await idToken.hasRole(MINTER_ROLE, minter)).to.equal(false)

    //         expect(idToken.revokeRole(UPGRADER_ROLE, upgrader, { from: other }))
    //         .to.be.revertedWith('AccessControl: account ${other} is missing ${DEFAULT_ADMIN_ROLE}')
    //         expect(await idToken.hasRole(UPGRADER_ROLE, upgrader)).to.equal(true)

    //         expect(idToken.revokeRole(DEFAULT_ADMIN_ROLE, admin)).to.emit(idToken, 'RoleRevoked')
    //         .withArgs(DEFAULT_ADMIN_ROLE, admin, admin)
    //         expect(await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(false)
    //     })
    // }) 

    // describe('renounce rules', function() {
    //     it('upgrader renounce self role with emitting events', async function() {
    //         expect(idToken.connect(upgrader).renounceRole(UPGRADER_ROLE, upgrader)).to.emit(idToken, 'RoleGranted')
    //         .withArgs(UPGRADER_ROLE, upgrader, admin)
    //         .to.emit(idToken, 'RoleRevoked').withArgs(UPGRADER_ROLE, upgrader, upgrader)
    //     })

    //     it('revert if renounce other roles', async function() {
    //         expect(idToken.renounceRole(MINTER_ROLE, minter)).to.be.rejectedWith('AccessControl: can only renounce roles for self')
    //     })
    // })

})

