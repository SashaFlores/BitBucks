//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

interface IBlacklist {

    event AccountBlacklisted(address indexed account);

    event AccountUnlisted(address indexed account);

    error _Blacklist_ZeroAddress();

    function isBlacklisted(address addr) external view returns(bool); 

    function listAddress(address addr) external returns(bool);

    function liftFromlist(address addr) external returns(bool);

}