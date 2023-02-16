//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import './interfaces/IMinterManager.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';


abstract contract MinterManager is Initializable, IMinterManager, OwnableUpgradeable {

    mapping(address => address[]) private _managers;
    mapping(address => mapping(address =>bool)) private _isManager;
    mapping(address => bool) internal exists;



    modifier onlyManager(address manager, address minter) {
        require(isManager(manager, minter) == true, 
        'Manager: manager and minter mismatch');
        _;
    }

    function __MinterManager_init() internal onlyInitializing {
        __Ownable_init();
    }

    function assignManager(address minter, address manager) public virtual override onlyOwner returns(bool) {
        _nonZeroAddress(minter);
        _nonZeroAddress(manager);
        require(!isMinter(minter), 'Manager: minter exists');
        require(minter != manager, 'Manager: minter and manager are the same address');
        _managers[manager].push(minter);
        exists[minter] = true;
        _isManager[manager][minter] = true;
        uint256 index = _managers[manager].length;
        emit ManagerAssigned(manager, minter, index);
        return _isManager[manager][minter];
    }

    function changeManager(address newManager, address prevManager, address minter, uint256 _index) public virtual override onlyOwner {
        require(isMinter(minter), 'Manager: minter does not exist');
        require(isManager(prevManager, minter) == true, 'Manager: not the right manager');
        _nonZeroAddress(newManager);
        if(_index >= _managers[prevManager].length) return;
        for(uint i = _index; i < _managers[prevManager].length - 1; i++) {
            _managers[prevManager][i] = _managers[prevManager][i+1];
        }
        _managers[prevManager].pop();
        _isManager[prevManager][minter] = false;

        _managers[newManager].push(minter);
        _isManager[newManager][minter] = true;
        emit ManagerChanged(prevManager, newManager);
    }

    function isManager(address manager, address minter) public view virtual override returns(bool){
        return _isManager[manager][minter];
    }

    function allManagerMinters(address manager) public view virtual override returns(address[] memory) {
        return _managers[manager];
    }

    function managerMintersCount(address manager) public view virtual override returns(uint256) {
        return _managers[manager].length;
    }

    function minterAddress(address manager, uint256 id) public view virtual override returns(address) {
        return _managers[manager][id];
    }

    function isMinter(address minter) public view virtual override returns(bool) {
        return exists[minter];
    }

    function _nonZeroAddress(address assignee) private pure  {
        require(assignee != address(0), 'Manager: unauthorized zero address');
    }

}
