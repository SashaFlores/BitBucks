const { ethers, getNamedAccounts, deployments } = require('hardhat')
const { UPGRADER_ROLE, DEFAULT_ADMIN_ROLE } = require('../../utils/constants')
const { expect } = require('chai')

describe('id token upgrade test', function() {
    
    let upgrader, admin, idToken, idTokenV2

    before(async() => {
        
        await deployments.fixture(['ids', 'implV2'])
        upgrader = (await getNamedAccounts()).upgrader
        admin = (await getNamedAccounts()).admin
        idToken = await ethers.getContract('IDToken', admin)
        idTokenV2 = await ethers.getContract('IDTokenV2', upgrader)   
    })

    describe('compatibility', function() {
        it('true admin', async function() {
            expect(await idToken.hasRole(DEFAULT_ADMIN_ROLE, admin)).to.equal(true)
        })
        it('true upgrader', async function() {
            expect(await idToken.hasRole(UPGRADER_ROLE, upgrader)).to.equal(true)
        })
        it('only upgrader can upgrade', async function() {
            expect(idToken.upgradeTo(idTokenV2.address))
            .to.be.revertedWith('AccessControl: account ${admin} is missing role ${UPGRADER_ROLE}')
        })
        it('upgrade reverts if contract not paused', async function() {
            expect(idToken.upgradeTo(idTokenV2.address))
            .to.be.revertedWith('Pausable: not paused')

            expect(await idToken.paused()).to.equal(false)
        })

    })

    describe('pause and upgrade', function() {
        before(async() => {
            await idToken.pauseOps()
        })
        
        it('emits paused event if true', async function() {
            expect(await idToken.paused()).to.equal(true)

            expect(idToken.pauseOps()).to.emit(idToken, 'Paused').withArgs(admin)
        })
        it('emits upgrade event if upgraded', async function() {
            await idToken.upgradeTo(idTokenV2.address)
            expect(idToken.connect(upgrader).upgradeTo(idTokenV2.address)).to.emit(idToken, 'Upgraded').withArgs(idTokenV2.address)

        })
    })

})
