//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import './interfaces/IManager.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/**
 * @title Manager
 * @author Sasha Flores
 * @dev Contract module that allows any child contract to implement the working model
 * mechanism. owner can assign manager to assignees & manager can be
 * responsible for more than one assignee.
 * manager duties are segregated in the child contract as see fit.
 */

abstract contract Manager is Initializable, IManager, OwnableUpgradeable {

    mapping(address => address[]) private _managers;
    mapping(address => bool) private exists;



    modifier onlyManager(address manager, address assignee) {
        require(isManager(manager, assignee) == true, 
        'Manager: manager and assignee mismatch');
        _;
    }

    modifier notZeroAddress(address addr) {
        if(addr == address(0))
            revert Manager_ZeroAddress();
        _;
    }

    function __Manager_init() internal onlyInitializing notZeroAddress(_msgSender()) {
        __Ownable_init();
    }

    function __Manager_init_unchained() internal onlyInitializing {}

    /**
     * @param manager address
     * @param assignee address
     * 
     * Requirements:
     * - `assignee` doesnot exist
     * - `assignee` & `manager` are non zero addresses
     * 
     * Emits {ManagerAssigned} event -check IManager
     */
    function assignManager
    (
        address manager,
        address assignee
    ) 
    public 
    virtual 
    override 
    notZeroAddress(assignee) 
    notZeroAddress(manager) 
    onlyOwner 
    {
        if(isAssignee(assignee))
            revert Manager_AssigneeExists();
 
        if(assignee == manager)
            revert Manager_SameAddress(manager, assignee);

        _managers[manager].push(assignee);
        exists[assignee] = true;
        uint256 index = _managers[manager].length;
        emit ManagerAssigned(manager, assignee, index);
    }

    /**
     * @param newManager address
     * @param prevManager address
     * @param assignee address
     * 
     * Requirements:
     * - `assignee` already listed
     * - `assignee` was assigned to `prevManager`
     * 
     * Emits {ManagerChanged} - check IManager
     */
    function changeManager
    (
        address newManager, 
        address prevManager, 
        address assignee
    ) 
    public 
    virtual 
    override 
    notZeroAddress(newManager) 
    onlyOwner 
    {
        if(!isAssignee(assignee))
            revert Manager_AssigneeNotExists();

        if(!isManager(prevManager, assignee))
            revert Manager_Mismatch(prevManager, assignee);
        
        if(prevManager == newManager)
            revert Manager_SameAddress(prevManager, newManager);

        uint256 index = assigneeIndex(prevManager, assignee);
        if(index >= _managers[prevManager].length) return;
        for(uint256 i = index; i < _managers[prevManager].length - 1; i++) {
           _managers[prevManager][i] = _managers[prevManager][i+1];
        }
        _managers[prevManager].pop();
        _managers[newManager].push(assignee);
        emit ManagerChanged(prevManager, newManager);
    }

    /**
     * @param assignee address
     * @param manager address
     * @notice removes `assignee` completely from assignees array
     * 
     * Emits {AssigneeRemoved} - check IManager
     */
    function removeAssignee(address assignee, address manager) public virtual override onlyOwner {
        if(!isAssignee(assignee))
            revert Manager_AssigneeNotExists();
        uint256 index = assigneeIndex(manager, assignee);
        if(index >= _managers[manager].length) return;
        for(uint256 i = index; i < _managers[manager].length - 1; i++) {
            _managers[manager][i] = _managers[manager][i+1];
        }
        _managers[manager].pop();
        exists[assignee] = false;
        emit AssigneeRemoved(assignee);
    }

    /**
     * @param manager address
     * @notice removes `manager` address completely 
     * reverts if assignees are still assigned to `manager`
     */
    function removeManager(address manager) public virtual override onlyOwner {
        if(_managers[manager].length <= 0) {
            delete _managers[manager]; 
        } else {
            revert Manager_NotEmpty();
        }         
        emit ManagerRemoved(manager);
    }

    /**
     * @param manager address
     * @param assignee address
     * @notice returns `assigneeIndex` in `manager` array
     * reverts if `assignee` doesn't exist in manager array
     */
    function assigneeIndex(address manager, address assignee) public view virtual override returns(uint256) {
        for(uint256 i = 0; i < _managers[manager].length; i++) {
            if(assignee == _managers[manager][i]) {
               return i;
            }
        }
        revert Manager_Mismatch(manager, assignee);
    }

    /**
     * @param manager address
     * @param assignee address
     * @notice returns true if `assignee` is assigned to `manager`
     */
    function isManager(address manager, address assignee) public view virtual override returns(bool){
        for(uint256 i = 0; i < _managers[manager].length; i++) {
            if(assignee == _managers[manager][i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice returns an array of assignees managed by `manager`
     */
    function allManagerAssignees(address manager) public view virtual override returns(address[] memory) {
        return _managers[manager];
    }

    /**
     * @notice returns total count of assignees managed by `manager`
     */
    function managerAssigneesCount(address manager) public view virtual override returns(uint256) {
        return _managers[manager].length;
    }

    /**
     * @notice returns the address of `assignee` managed by `manager` at index `id`
     */
    function assigneeAddress(address manager, uint256 id) public view virtual override returns(address) {
        return _managers[manager][id];
    }

    /**
     * @notice returns true if `assignee` exists
     */
    function isAssignee(address assignee) public view virtual override returns(bool) {
        return exists[assignee];
    }

}
