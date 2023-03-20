//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './interfaces/IRealtyFactory.sol';
import './interfaces/IDTokenInterface.sol';
import './proxy/UpgradeableBeacon.sol';
import './BitRealty.sol';
import './Manager.sol';


contract RealtyFactory is Initializable, IRealtyFactory, Manager, PausableUpgradeable, UpgradeableBeacon {


  IDTokenInterface private ID;
  address[] private proxies;
  mapping(address => address[]) private ownerRealties;
  mapping(uint256 => address) private taxAddress;
  mapping(uint256 => bool) existing;



  function __RealtyFactory_init(address idContract, address impl) public virtual override initializer notZeroAddress(_msgSender()) notZeroAddress(idContract) notZeroAddress(impl){
    __Manager_init();
    __Pausable_init();
    __UpgradeableBeacon_init(impl);

    ID = IDTokenInterface(idContract);
  }


  function mintNft
  (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _tokenURI,
    address to, 
    uint256 taxId,
    string memory state, 
    string memory city, 
    uint256 zipcode
  ) 
  public 
  virtual 
  override 
  whenNotPaused 
  NotBlacklisted(_msgSender()) 
  NotBlacklisted(to) 
  notZeroAddress(_msgSender()) 
  notZeroAddress(to) 
  returns(address) 
  {
    // require(ID.isVerified(msg.sender) || ID.isVerified(to),"RealtyFactory: verified holders only");
    require(!existing[taxId], "RealtyFactory: tax ID exists");
    existing[taxId] = true;

    address newProxy = address(new BeaconProxy(address(this), ''));
    BitRealty(newProxy).__BitRealty_init(_tokenName, _tokenSymbol, _tokenURI, to, state, city, zipcode);
    

    proxies.push(address(BitRealty(newProxy)));

    uint256 proxyCount = proxies.length;

    BitRealty(newProxy).transferOwnership(msg.sender);
    
    taxAddress[taxId] = address(BitRealty(newProxy));

    ownerRealties[msg.sender].push(address(BitRealty(newProxy)));
   
    emit ProxyDeployed(proxyCount, address(BitRealty(newProxy)), _msgSender());
    
    return address(BitRealty(newProxy));
  }  

  function modifyProxyURI(address realty, uint256 tokenId, string memory newURI) public virtual override onlyManager(_msgSender(), realty) whenNotPaused returns(bool){
    (bool success, ) = 
    realty.call(abi.encodeWithSelector(BitRealty.modifyTokenURI.selector, tokenId, newURI));
    require(success, 'RealtyFactory: modify URI failed');
    return  success;
  }

  function modifyProxyMetadata(address realty, uint256 tokenId, string memory newName, string memory newSymbol) public virtual override onlyManager(_msgSender(), realty) whenNotPaused returns(bool) {
    (bool success, ) = 
    realty.call(abi.encodeWithSelector(BitRealty.modifyTokenMetadata.selector, tokenId, newName, newSymbol));
    require(success, 'RealtyFactory: modify metadata failed');
    return success;
  }

  function allOwnerRealties(address owner) external view virtual override returns(address[] memory) {
    return ownerRealties[owner];
  }

  function totalownerRealties(address owner) external view virtual override returns(uint256) {
    return ownerRealties[owner].length;
  }

  function realtyAddress(address owner, uint256 id) external view virtual override returns(address) {
    return ownerRealties[owner][id];
  }

  function realtyByTax(uint256 taxId) external view virtual override returns(address) {
    return taxAddress[taxId];
  }

  function allProxies() external view virtual override returns(address[] memory) {
    return proxies;
  }

  function proxiesCount() external view virtual override returns(uint256) {
    return proxies.length;
  }

  function proxyAddrById(uint256 num) external view override returns(address) {
    return proxies[num];
  }

  function taxIdExists(uint256 taxId) public view returns(bool) {
    return existing[taxId];
  }

  function emergencyPause() external virtual override onlyOwner {
    _pause();
  }

  function emergencyUnpause() external virtual override onlyOwner {
    _unpause();
  }

  function isPaused() public view virtual override returns(bool) {
    return paused();
  }

 
}