//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import './interfaces/IRealtyFactory.sol';
import './interfaces/IBitRealty.sol';



contract BitRealty is 
   Initializable, 
   IBitRealty,
   OwnableUpgradeable,
   ERC721Upgradeable,
   ReentrancyGuardUpgradeable 
 {


   IRealtyFactory private factory;
   uint256 private _tokenId;   
   address private _to;

   mapping(uint256 => string) private _tokenURIs;                              
   mapping(uint256 => mapping(address => Entity)) private entities;  
         
   struct Entity {
      string state;
      string city;
      uint256 zipcode;
      string tokenName;    
      string tokenSymbol;  
      string tokenURI;
   }

   function __BitRealty_init(
      string memory _tokenName,
      string memory _tokenSymbol,
      string memory _tokenURI,
      address to, 
      string memory state, 
      string memory city, 
      uint256 zipcode

   ) public override initializer nonReentrant {
      __Ownable_init();
      __ERC721_init(_tokenName, _tokenSymbol);
      __ReentrancyGuard_init();

      factory = IRealtyFactory(msg.sender);
      require(msg.sender != address(0), "BitsRealty: Factory is address zero");
 
      _to = to;
      _safeMint(to, _tokenId);
      _tokenId = factory.proxiesCount();
      _setTokenURI(_tokenId, _tokenURI);

      entities[_tokenId][to] = Entity(state, city, zipcode, _tokenName, _tokenSymbol, _tokenURI);
   }

   function isPaused() public view returns(bool) {
      return factory.isPaused();
   }

   function totalSupply() public view virtual override returns(uint256) {
      return factory.proxiesCount();
   }

 


   function modifyTokenMetadata(uint256 tokenId, string memory _name, string memory _symbol) public virtual override
   {
      require(!factory.isPaused(), 'BitsRealty: operations paused');
      require(_msgSender() == address(factory), "BitsRealty: unauthorized call");
      Entity storage entity = entities[tokenId][_to];
      entity.tokenName = _name;
      entity.tokenSymbol = _symbol;

      emit MetadataChanged(tokenId, _name, _symbol);
   }

   function name(uint256 tokenId) public view virtual override returns(string memory) {
      _requireMinted(tokenId);
      return entities[tokenId][_to].tokenName;
   }

   function symbol(uint256 tokenId) public view virtual override returns(string memory) {
      _requireMinted(tokenId);
      return entities[tokenId][_to].tokenSymbol;
   }

   function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, IBitRealty) returns(string memory) {
      _requireMinted(tokenId);
      return _tokenURIs[tokenId];
   }

   //returns `state`, `city`, `zipcode` of `tokenId`
   function tokenLocation(uint256 tokenId) public view virtual override returns(string memory, string memory, uint256) {
      return (entities[tokenId][_to].state, entities[tokenId][_to].city, entities[tokenId][_to].zipcode);
   }

   function modifyTokenURI(uint256 tokenId, string memory uri) public virtual override {
      require(_msgSender() == address(factory), "BitsRealty: unauthorized call");

      _setTokenURI(tokenId, uri);
      emit TokenURIModified(tokenId, uri, msg.sender);
   }

  function supportsInterface
  (
   bytes4 interfaceId
   ) 
   public 
   view 
   virtual 
   override(ERC721Upgradeable) 
   returns (bool) 
   {
    return 
    interfaceId == type(IERC721Upgradeable).interfaceId ||
    interfaceId == type(IBitRealty).interfaceId ||
    super.supportsInterface(interfaceId);
  }

   function setApprovalForAll(address operator, bool approved) public virtual override {
      require(!factory.isPaused(), 'BitsRealty: operations paused');
      super.setApprovalForAll(operator, approved);
   }

   function burn(uint256 tokenId) public virtual override onlyOwner {
         if(bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
         }
      _burn(tokenId);
      selfdestruct(payable(msg.sender));
   }

   //approve `to` address as an operator of `tokenId`
   function approve(address to, uint256 tokenId) public virtual override {
      require(!factory.isPaused(), 'BitsRealty: operations paused');
      super.approve(to, tokenId);
   }

   //returns version of this contract
   function version() public pure virtual returns(string memory) {
      return "V1.0.0";
   }

   function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
     _requireMinted(tokenId);
      _tokenURIs[tokenId] = _tokenURI;
   }


   function _beforeTokenTransfer
   (
      address from, 
      address to, 
      uint256 firstTokenId, 
      uint256 batchSize
   ) 
   internal 
   virtual 
   override(ERC721Upgradeable) 
   {
      require(!factory.isPaused(), 'BitsRealty: operations paused');
      super._beforeTokenTransfer(from, to, firstTokenId, batchSize);     
   }

 }