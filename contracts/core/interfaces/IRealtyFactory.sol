//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/proxy/beacon/IBeacon.sol';

interface IRealtyFactory is IBeacon {
    
    event ProxyDeployed(uint256 proxyId, address proxyAddress, address indexed initiator);
    
    function __RealtyFactory_init(address idContract, address impl) external;

    function mintNft(string memory tokenName,
      string memory tokenSymbol,
      string memory tokenURI,
      address to, 
      uint256 taxId,
      string memory state, 
      string memory city, 
      uint256 zipcode) external returns(address);

    function allOwnerRealties(address owner) external view returns(address[] memory);

    function totalownerRealties(address owner) external view returns(uint256);

    function realtyAddress(address owner, uint256 id) external view returns(address);

    function realtyByTax(uint256 taxId) external view returns(address);

    function allProxies() external view returns(address[] memory);

    function proxiesCount() external view returns(uint256);

    function proxyAddrById(uint256 num) external view returns(address);

    function modifyProxyURI(address estateContract, uint256 tokenId, string memory newURI) external returns(bool);

    function modifyProxyMetadata(address estateContract, uint256 tokenId, string memory newName, string memory newSymbol) external returns(bool);

    function emergencyPause() external;

    function emergencyUnpause() external;

    function isPaused() external view returns(bool);

}