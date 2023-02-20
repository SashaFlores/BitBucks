//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './interfaces/IBlacklist.sol';


abstract contract Blacklist is Initializable, IBlacklist, OwnableUpgradeable {

    mapping (address => bool) private _blacklist;

    modifier NotBlacklisted {
        require(!isBlacklisted(_msgSender()), 'Blacklisted: blacklisted');
        _;
    }
    function __Blacklist_init() internal onlyInitializing {
        __Ownable_init();
    }

    function isBlacklisted(address addr) public view virtual override returns(bool) {
        return _blacklist[addr];
    }

    function listAddress(address addr) public virtual override onlyOwner NotBlacklisted returns(bool) {
        if(addr == address(0)) {
            revert _Blacklist_ZeroAddress();
        }
        _blacklist[addr] = true;
        
        emit AccountBlacklisted(addr);

        return isBlacklisted(addr);
    }

    function liftFromlist(address addr) public virtual override onlyOwner returns(bool) {
        require(isBlacklisted(addr), 'Blacklist: not blacklisted');
        _blacklist[addr] = false;

        emit AccountUnlisted(addr);

        return isBlacklisted(addr);
    }

}