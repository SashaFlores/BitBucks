//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import './Blacklist.sol';
import './interfaces/IDTokenInterface.sol';

/**
 * @title IDToken
 * @author Sasha Flores
 * @dev allows EOA and contracts to mint ID Token from available token ids
 * all tokens arenot transferrable except for `Business` token 
 */

// solhint-disable-next-line contract-name-camelcase
contract IDToken is 
    Initializable, 
    IDTokenInterface, 
    EIP712Upgradeable, 
    ERC1155Upgradeable, 
    AccessControlUpgradeable, 
    Blacklist,
    UUPSUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable 
{

    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 private _deadline;
    mapping(uint256 => uint256) private supply;
    mapping(address => bool) private verified;
    mapping(address => CountersUpgradeable.Counter) private nonces;


    /**
     * constant varaibles - non storage variables
     */
    bytes32 private constant UPGRADER_ROLE = keccak256(abi.encodePacked('UPGRADER_ROLE'));
    bytes32 private constant MINTER_ROLE = keccak256(abi.encodePacked('MINTER_ROLE'));
    bytes32 private constant MANAGER_ROLE = keccak256(abi.encodePacked('MANAGER_ROLE'));

    // keccak256('Mint(uint256 id,uint256 nonce)')
    bytes32 private constant MINT_TYPEHASH = 0x588a89f2bcfeb8ba98af456d132a03a13826dcdf6236c16ea72653bdfb6fe5a0;
    // keccak256('Burn(address from,uint256 id,uint256 nonce)')
    bytes32 private constant BURN_TYPEHASH = 0x65ec0a3d9b23902e2fe999689a69e8e5ad5bcaab57b8635aec70eaae30d3d87f;
    // keccak256('TransferBusiness(address from,address to,uint256 nonce)')
    bytes32 private constant TRANSFERBUSINESS_TYPEHASH = 0x08fbd4ddd267b352a91e83af6df8e0f1646949469c7ea3ee6e7c829e0216ff31;


    uint256 public constant BUSINESS = 1;
    uint256 public constant US_PERSONA = 2;
    uint256 public constant INT_PERSONA = 3;
    uint256 public constant US_INVERSTOR = 4;
    uint256 public constant INT_INVESTOR = 5;

    

    // solhint-disable-next-line func-name-mixedcase
    function __IDToken_init(address upgrader, address manager, string memory uri_) external initializer virtual override{
        __EIP712_init('IDToken', '1.0.0');
        __ERC1155_init(uri_);
        __Blacklist_init();  
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _nonZeroAddress(_msgSender());
        _setupRole(UPGRADER_ROLE, upgrader);
        _nonZeroAddress(upgrader);
        _setupRole(MANAGER_ROLE, manager);
        _nonZeroAddress(manager);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(AccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name() public pure virtual returns(string memory) {
        return 'IDToken';
    }

    function symbol() public pure virtual returns(string memory) {
        return 'IDT';
    }

    function version() public pure virtual returns(string memory) {
        return '1.0.0';
    }

    function chainId() public view returns(uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function totalSupply(uint256 id) public view virtual override returns(uint256) {
        return supply[id];
    }

    function isVerified(address account) public view virtual override returns(bool) {
        return verified[account];
    }

    function pauseOps() external virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(UPGRADER_ROLE, _msgSender()), 'missing role');
        _pause();
    }

    function unpauseOps() external virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(UPGRADER_ROLE, _msgSender()), 'missing role');
        _unpause();
    }

    function exists(uint256 id) external view virtual override returns(bool) {
        return IDToken.totalSupply(id) > 0;
    }

    function updateURI(string memory uri_) external virtual override onlyRole(MANAGER_ROLE) whenNotPaused {
        _setURI(uri_);
    }

    function grantMinterRole
    (
        address minter, 
        uint256 id, 
        uint256 deadline
    ) 
    public 
    virtual 
    override 
    onlyRole(MANAGER_ROLE) 
    NotBlacklisted
    whenNotPaused 
    returns(bool) 
    {
        _nonZeroAddress(minter);
        _availIds(id);

        _deadline = deadline;
        

        if(balanceOf(minter, id) != 0) {
            revert IDToken_FailedGrantRole(minter, id);
        } 
        _grantRole(MINTER_ROLE, minter);
        emit MinterSet(minter, id);
        return hasRole(MINTER_ROLE, minter);
    }

    function signerNonce(address signer) public view virtual override returns(uint256) {
        return nonces[signer].current();
    }

    function mint(uint256 id, bytes calldata signature) public virtual override NotBlacklisted whenNotPaused nonReentrant {
        require(block.timestamp < _deadline, 'pass deadline');

        bytes32 txHash = mintHash(id, _incrementNonce(_msgSender()));
        require(verifySignature(_msgSender(), txHash, signature), 'invalid signature');

        _mint(_msgSender(), id, 1, '');
        supply[id] ++;
        verified[_msgSender()] = true;
    }

    function mintHash(uint256 id, uint256 _nonce) public view virtual returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MINT_TYPEHASH, id, _nonce)));
    }

    function burn(address from, uint256 id, bytes calldata signature) public virtual override NotBlacklisted whenNotPaused {
       
        bytes32 taxHash = burnHash(from, id, _incrementNonce(_msgSender()));
        require(verifySignature(from, taxHash, signature), 'invalid signature');

        _burn(_msgSender(), id, 1);
        supply[id] --;
        verified[_msgSender()] = true;
    }

    function burnHash(address from, uint256 id, uint256 _nonce) public view virtual returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(BURN_TYPEHASH, from, id, _nonce)));
    }

    function transferBusiness(address from, address to, bytes[] memory signatures) public virtual override NotBlacklisted {
        require(signatures.length == 2, 'Owner and manager signatures are needed');
        bytes32 txHash = keccak256(abi.encode(TRANSFERBUSINESS_TYPEHASH, from, to, _incrementNonce(_msgSender())));
        bytes32 hash = _hashTypedDataV4(txHash);

        require(verifySignature(_msgSender(), hash, signatures[0]), 'invalid owner signature');
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(_msgSender(), hash, signatures[1]) &&
            hasRole(MANAGER_ROLE, _msgSender()), 'invalid manager signature'
        );

        _safeTransferFrom(from, to, 1, 1, '');
    }

    function verifySignature(address signer, bytes32 txHash, bytes memory signature) public view returns(bool) {
        return hasRole(MINTER_ROLE, signer) && SignatureCheckerUpgradeable.isValidSignatureNow(signer, txHash, signature);
    }

    function _incrementNonce(address signer) internal virtual returns(uint256 current) {
        CountersUpgradeable.Counter storage nonce = nonces[signer];
        current = nonce.current();
        nonce.increment();
    }

    function _beforeTokenTransfer
    (
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override 
    {
        require(!paused(), 'contract is paused');
        for(uint256 i = 0; i <= ids.length; i++) {
            uint256 id = ids[i];
            if(id != 1) {
                require(
                    from == address(0) && to != address(0) || 
                    from != address(0) && to == address(0), 
                    'transfer is not allowed'
                );
            }

        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {
        _nonZeroAddress(newImplementation);
        require(AddressUpgradeable.isContract(newImplementation), 'new implementation not contract');
        require(paused(), 'pause ops before upgrade');
    }

    function _availIds(uint256 id) private pure {
        uint256[5] memory availIds;
        require(id <= availIds.length, 'unavailable id yet');
    }

    function _nonZeroAddress(address _address) private pure {
        require(_address != address(0), 'address zero unauthorized');
    }

}
