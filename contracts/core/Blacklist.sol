//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './interfaces/IBlacklist.sol';

/**
 * @title Blacklist
 * @author Sasha Flores
 * @dev light module to be implemented by child contracts to blacklist
 * or lift from list accounts with red flags
 */
abstract contract Blacklist is Initializable, IBlacklist, OwnableUpgradeable {

    mapping (address => bool) private _blacklist;

    modifier NotBlacklisted {
        if(isBlacklisted(_msgSender()))
            revert Blacklist_Listed();
        _;
    }


    function __Blacklist_init() internal onlyInitializing {
        __Ownable_init();
    }

    function __Blacklist_init_unchained() internal onlyInitializing{}


    /**
     * @notice returns if address `addr` is blacklisted
     */
    function isBlacklisted(address addr) public view virtual override returns(bool) {
        return _blacklist[addr];
    }

    /**
     * @notice list `addr` as blacklisted if not listed before
     * 
     * Requirements:
     * non zero address
     * accessible by onwer only
     * 
     * Emits {AccountBlacklisted} event
     */
    function listAddress(address addr) public virtual override onlyOwner NotBlacklisted returns(bool) {
        if(addr == address(0)) 
            revert Blacklist_ZeroAddress();

        _blacklist[addr] = true;
        
        emit AccountBlacklisted(addr);

        return isBlacklisted(addr);
    }

    /**
     * @notice lift `addr` as blacklisted if listed before
     * 
     * Requirements:
     * address `addr` was blacklisted.
     * accessible by owner only 
     * 
     * Emits {AccountUnlisted} event
     */
    function liftFromList(address addr) public virtual override onlyOwner returns(bool) {
        if(!isBlacklisted(addr))
            revert Blacklist_NotListed();

        _blacklist[addr] = false;

        emit AccountUnlisted(addr);

        return isBlacklisted(addr);
    }

}