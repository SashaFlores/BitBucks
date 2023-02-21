//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

interface IDTokenInterface {

    event MinterSet(address indexed minter, uint256 id);

    error IDToken_FailedGrantRole(address minter, uint256 assignedId);

    function __IDToken_init(address upgrader, address manager, string memory uri_) external;

    function totalSupply(uint256 id) external returns(uint256);

    function grantMinterRole(address minter, uint256 id, uint256 deadline) external returns(bool);

    function transferBusiness(address from, address to, bytes[] memory signatures) external;

    function isVerified(address account) external returns(bool);

    function signerNonce(address signer) external view returns(uint256);
    
    function mint(uint256 id, bytes calldata signature) external;

    function burn(address addr, uint256 id, bytes calldata signature) external;

    function updateURI(string memory uri_) external;

    function exists(uint256 id) external returns(bool);
}