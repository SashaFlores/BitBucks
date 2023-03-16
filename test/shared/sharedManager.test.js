const { ethers, deployments, getNamedAccounts, getUnnamedAccounts } = require('hardhat')
const { expect, assert } = require('chai')
const { ZERO_ADDRESS } = require('../../utils/constants')


function sharedManagerTest(getContract) {
    let deployer, manager, manager1, manager2, users, _managers, user0Index, manager1Assignees, user1Index, manager2Assignees

    beforeEach(async function() {
        await deployments.fixture('ids')
        deployer = (await getNamedAccounts()).deployer
        manager1 = (await getNamedAccounts()).manager1
        manager2 = (await getNamedAccounts()).manager2
        users = await getUnnamedAccounts()
        const idToken = await ethers.getContract('IDToken', deployer)
        manager = await ethers.getContractAt('Manager', idToken.address)
    })

    describe('test ownership', function() {
        it('deployer is owner', async function() {
            expect(await manager.owner()).to.equal(deployer)
        })
        it('reject ownership transfer to zero address', async function() {
            expect(manager.transferOwnership(ZERO_ADDRESS)).to.be.rejectedWith('Ownable: new owner is the zero address')
        })
        it('only owner can transfer ownership', async function() {
            expect(manager.transferOwnership(manager1, {from: manager2})).to.be.revertedWith('Ownable: caller is not the owner')
            expect(manager.transferOwnership(manager1, {from: manager2})).to.not.emit('OwnershipTransfer')
        })
        it('owner transfer ownership and emits event', async function() {
            await manager.transferOwnership(manager1)
            expect(await manager.owner()).to.equal(manager1)
            expect(manager.transferOwnership(manager1)).to.emit(manager, 'OwnershipTransfer').withArgs(deployer, manager1)
        })
    })

    describe('test renounce function', function() {
        it('only owner can renounce', async function() {
            expect(manager.renounceOwnership({from: manager1})).to.be.revertedWith('Ownable: caller is not the owner')
            expect(manager.renounceOwnership()).to.not.emit('OwnershipTransfer')
        })
        it('owner renounce ownership and emits event', async function() {
            await manager.renounceOwnership()
            expect(await manager.owner()).to.equal(ZERO_ADDRESS)
            expect(manager.renounceOwnership()).to.emit(manager, 'OwnershipTransfer').withArgs(deployer, ZERO_ADDRESS)
        })
    })

    describe('test assign manager function', function() {
        beforeEach(async function() {
            await manager.assignManager(manager1, users[0])
            _managers = new Map()
            _managers.set(manager1, [users[0]])
            manager1Assignees = _managers.get(manager1)
            user0Index = manager1Assignees.indexOf(users[0])
        })
        
        it('only owner can assign', async function() {
            expect(manager.assignManager(manager1, users[0], {from: manager2})).to.be.revertedWith('Ownable: caller is not the owner')
        })

        it('reject address zero', async function() {
            expect(manager.assignManager(ZERO_ADDRESS, users[0])).to.be.revertedWithCustomError(manager, 'Manager_ZeroAddress')
            expect(manager.assignManager(manager1, ZERO_ADDRESS)).to.be.revertedWithCustomError(manager, 'Manager_ZeroAddress')
        })

        it('reject same address for manager and assignee', async function() {
            expect(manager.assignManager(users[1], users[1])).to.be.revertedWithCustomError(manager, 'Manager_SameAddress')
            .withArgs(users[1], users[1])
        })

        it('returns true if assignee exists', async function() {
            expect(await manager.isAssignee(users[0])).to.equal(true)
        })

        it('returns true if manager assigned to assignee', async function() {
            expect(await manager.isManager(manager1, users[0])).to.equal(true)
        })

        it('revert if re-assign existed assignee', async function() {
            expect(manager.assignManager(manager2, users[0])).to.be.revertedWithCustomError(manager, 'Manager_AssigneeExists')
            expect(await manager.isManager(manager2, users[0])).to.equal(false)
        })

        it('get total number of assignees to manager', async function() {
            expect(await manager.managerAssigneesCount(manager1)).to.equal(await _managers.get(manager1).length)
        })

        it('gets assignee address', async function() {
            expect(await manager.assigneeAddress(manager1, user0Index)).to.equal(users[0])
        })

        it('gets assignee index if exist', async function() {
            expect(await manager.assigneeIndex(manager1, users[0])).to.equal(user0Index)
        })

        it('reverts assignee index if assignee does not exist', async function() {
            expect(manager.assigneeIndex(manager1, users[1])).to.be
            .revertedWithCustomError(manager, 'Manager_Mismatch').withArgs(manager1, users[1])
            expect(await manager.isAssignee(users[1])).to.equal(false)
        })

        it('gets all assignees assigned to manager', async function() {
            assert.deepEqual(manager1Assignees, [users[0]])
            assert.strictEqual(_managers.size, 1)
        })

        it('emits manager assign event', async function() {
            expect(manager.assignManager(manager1, users[0])).to.emit(manager, 'ManagerAssigned').withArgs(manager1, users[0], user0Index)
        })
    })

    describe('test changing previously assigned manager function', function() {
        beforeEach(async function() {
            await manager.assignManager(manager1, users[0])
            await manager.assignManager(manager1, users[1])
            await manager.changeManager(manager2, manager1, users[1])

            _managers = new Map()
            if(_managers.has(manager1, manager2)) {
                // check if `manager` already exists
                _managers.get(manager1).push(users[0])
                _managers.get(manager2).push(users[1])
            } else {
                // update mapping with new assignee
                _managers.set(manager1, [users[0]])
                _managers.set(manager2, [users[1]])
            }
            manager1Assignees = _managers.get(manager1)
            user0Index = manager1Assignees.indexOf(users[0])
            manager2Assignees = _managers.get(manager2)
            user1Index = manager2Assignees.indexOf(users[1])
        })
        it('accessible by deployer only', async function() {
            expect(manager.changeManager(manager2, manager1, users[1], {from: manager1})).to.be.revertedWith('Ownable: caller is not the owner')
            expect(manager.changeManager(manager2, manager1, users[1])).to.not.emit('ManagerChanged')
        })
        it('reverts zer address for new manager', async function() {
            expect(manager.changeManager(ZERO_ADDRESS, manager1, users[1])).to.be.revertedWithCustomError(manager, 'Manager_ZeroAddress')
        })
        it('emits manager changed event', async function() {
            expect(manager.changeManager(manager2, manager1, users[1])).to.emit(manager, 'ManagerChanged').withArgs(manager1, manager2)
        })
        it('check initial manager manages assignee one', async function() {
            expect(await manager.isManager(manager1, users[0])).to.equal(true)
        })
        it('check initial manager manages assignee two', async function() {
            expect(await manager.isManager(manager1, users[1])).to.equal(false)
        })
        it('check new manager manages assignee two', async function() {
            expect(await manager.isManager(manager2, users[1])).to.equal(true)
        })
        it('reverts if assignee does not exist', async function() {
            expect(manager.changeManager(manager2, manager1, users[2])).to.be.revertedWithCustomError(manager, 'Manager_AssigneeNotExists')
        })
        it('reverts if prev manager was not previously assigned to assignee', async function() {
            expect(manager.changeManager(manager2, users[2], users[1])).to.be
            .revertedWithCustomError(manager, 'Manager_Mismatch').withArgs(users[2], users[1])
        })
        it('reverts if prev manager same as new manager', async function() {
            expect(manager.changeManager(manager1, manager1, users[1])).to.be.revertedWithCustomError(manager, 'Manager_SameAddress')
        })
        it('returns correct index of assignee one', async function() {
            expect(await manager.assigneeIndex(manager1, users[0])).to.equal(user0Index)
        })
        it('returns correct index of assignee two', async function() {
            expect(await manager.assigneeIndex(manager2, users[1])).to.equal(user1Index)
        })
        it('reverts assignee index if not with right manager', async function() {
            expect(manager.assigneeIndex(manager2, users[0])).to.be
            .revertedWithCustomError(manager, 'Manager_Mismatch').withArgs(manager2, users[0])
            expect(manager.assigneeIndex(manager1, users[1])).to.be
            .revertedWithCustomError(manager, 'Manager_Mismatch').withArgs(manager1, users[1])
        })
        it('returns total assignees per each manager', async function() {
            expect(await manager.managerAssigneesCount(manager1)).to.equal(await _managers.get(manager1).length)
            expect(await manager.managerAssigneesCount(manager2)).to.equal(await _managers.get(manager2).length)
        })
        it('gets assignee address per manager and index', async function() {
            expect(await manager.assigneeAddress(manager1, user0Index)).to.equal(users[0])
            expect(await manager.assigneeAddress(manager2, user1Index)).to.equal(users[1])
        })
        it('returns assignee addresses per manager', async function() {
            assert.deepEqual(manager1Assignees, [users[0]])
            assert.deepEqual(manager2Assignees, [users[1]])
            assert.strictEqual(_managers.size, 2)
        })
    })
    describe('test remove assignee function', function() {
        beforeEach(async function() {
            await manager.assignManager(manager1, users[0])
            await manager.removeAssignee(users[0], manager1)
        })

        it('accessible by deployer only', async function() {
            expect(manager.removeAssignee(users[0], manager1, {from: manager1})).to.be.revertedWith('Ownable: caller is not the owner')
        })
        it('emits assignee removed event', async function() {
            expect(manager.removeAssignee(users[0], manager1, {from: manager1})).to.emit(manager, 'AssigneeRemoved').withArgs(users[0])
        })
        it('reverts if assignee was not previously assigned', async function() {
            expect(manager.removeAssignee(users[1], manager1)).to.be.revertedWithCustomError(manager, 'Manager_AssigneeNotExists')
        })
        it('assignee is removed', async function() {
            expect(await manager.isAssignee(users[0])).to.equal(false)
        })
        it('reverts if assignee mismatch manager', async function() {
            expect(manager.removeAssignee(users[0], manager2)).to.be.revertedWithoutReason
        })
        it('manager returns false if assignee removed', async function() {
            expect(await manager.isManager(manager1, users[0])).to.equal(false)
        })
    })
    describe('test remove manager function', function() {
        beforeEach(async function() {
            await manager.assignManager(manager2, users[1])
        })
        it('unable to remove manager as long as assignee exist', async function() {
            expect(manager.removeManager(manager2)).to.be.revertedWithCustomError(manager, 'Manager_NotEmpty')
        })
        it('check accessibility and remove manager and assignee', async function() {
            await manager.removeAssignee(users[1], manager2)
            expect(await manager.isAssignee(users[1])).to.equal(false)

            await manager.removeManager(manager2)
            expect(manager.removeManager(manager2, {from: manager2})).to.be.revertedWith('Ownable: caller is not the owner')
            expect(manager.removeManager(manager2)).to.emit(manager, 'ManagerRemoved').withArgs(manager2)
            expect(await manager.managerAssigneesCount(manager2)).to.equal(0)
        })
    })
}
module.exports = { sharedManagerTest }

