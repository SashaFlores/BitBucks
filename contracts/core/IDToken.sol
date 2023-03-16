//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import './Blacklist.sol';
import './Manager.sol';
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
    Manager, 
    Blacklist,
    UUPSUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable 
{

    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // tracks contract supply
    mapping(uint256 => uint256) private supply;
    // true if address verified
    mapping(address => bool) private verified;
    // prevent replay attacks
    mapping(address => CountersUpgradeable.Counter) private nonces;



    // keccak256('Mint(uint256 id,uint256 deadline,uint256 nonce)')
    bytes32 private constant MINT_TYPEHASH = 0x34a81dce1fc51da43c6636a0c631893770c79195cd9e729fab52685f029d1d4c;
    // keccak256('Burn(address from,uint256 id,uint256 nonce)')
    bytes32 private constant BURN_TYPEHASH = 0x65ec0a3d9b23902e2fe999689a69e8e5ad5bcaab57b8635aec70eaae30d3d87f;
    // keccak256('TransferBusiness(address from,address to,uint256 nonce)')
    bytes32 private constant TRANSFERBUSINESS_TYPEHASH = 0x08fbd4ddd267b352a91e83af6df8e0f1646949469c7ea3ee6e7c829e0216ff31;


    uint256 public constant BUSINESS = 1;
    uint256 public constant US_PERSONA = 2;
    uint256 public constant INT_PERSONA = 3;
    uint256 public constant US_INVERSTOR = 4;
    uint256 public constant INT_INVESTOR = 5;

    
    modifier availIds() {
        uint256[5] memory ids;
        for(uint256 i = 0; i <= ids.length; i++) {
            uint256 id = ids[i];
            if(id > ids.length) 
            revert IDToken_UnavailID();
        }
        _;
    }



    /**
     * @param uri_ string, metadata of tokens by replacing `id` number
     * Requirements:
     * non zero address isn't allowed 
     * 
     * Emits a {OwnershipTransfer} event - check Ownable
     */
    

    // solhint-disable-next-line func-name-mixedcase
    function __IDToken_init(string memory uri_) public initializer virtual override notZeroAddress(_msgSender()) {
        __EIP712_init('BitBucks', '1.0.0');
        __ERC1155_init(uri_);
        __Blacklist_init();  
        __Manager_init();
        __UUPSUpgradeable_init();
        __Pausable_init();

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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

    function chainId() public view virtual returns(uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function totalSupply(uint256 id) public view virtual override availIds returns(uint256) {
        return supply[id];
    }

    function isVerified(address account) public view virtual override returns(bool) {
        return verified[account];
    }

    function pauseOps() external virtual onlyOwner {
        _pause();
    }

    function unpauseOps() external virtual onlyOwner {
        _unpause();
    }

    function minted(uint256 id) external view virtual override availIds returns(bool) {
        return IDToken.totalSupply(id) > 0;
    }


    function updateURI(string memory uri_) external virtual override onlyOwner whenNotPaused {
        _setURI(uri_);
    }
    /**
     * @notice returns latest nonce used by signer
     */
    function signerNonce(address signer) public view virtual override returns(uint256) {
        return nonces[signer].current();
    }

    /**
     * @notice verify minter's `signature` & `id` from `availIds`
     * 
     * Requirements:
     * signature within deadline
     * balance of `signer` of token `id` should be zero before minting
     * `signer` is an assignee
     * `signer` isnot blacklisted
     * contract isnot paused
     * `id` is from `availIds`
     * 
     * Emits a {TransferSingle} - check ERC1155
     */
    function mint
    (
        uint256 id, 
        uint256 deadline, 
        bytes calldata signature
    ) 
    public
    virtual 
    override 
    availIds 
    NotBlacklisted 
    whenNotPaused 
    nonReentrant 
    {
        if(balanceOf(_msgSender(), id) != 0) 
            revert IDToken_IdMinted(_msgSender(), balanceOf(_msgSender(), id));

        require(block.timestamp < deadline, 'pass deadline');

        bytes32 txHash = mintHash(id, deadline, _incrementNonce(_msgSender()));
        if(!verifySignature(_msgSender(), txHash, signature))
            revert IDToken_invalidSignature(_msgSender());
       
        _mint(_msgSender(), id, 1, '');
        supply[id] ++;
        verified[_msgSender()] = true;
    }

    /**
     * @notice returns bytes32 hash of mint function
     */
    function mintHash(uint256 id, uint256 deadline, uint256 _nonce) public view virtual availIds returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MINT_TYPEHASH, id, deadline, _nonce)));
    }

    /**
     * @notice burns token `id` from `from` balance
     * 
     * Requirements:
     * from `from` has balance of token `id`
     * caller is an assignee
     * `signer` isnot blacklisted
     * contract isnot paused
     * `id` is from `availIds`
     * 
     * Emits a {TransferSingle} - check ERC1155
     */
    function burn(address from, uint256 id, bytes calldata signature) public virtual override availIds NotBlacklisted whenNotPaused {
       
        bytes32 txHash = burnHash(from, id, _incrementNonce(_msgSender()));
        if(!verifySignature(_msgSender(), txHash, signature))
            revert IDToken_invalidSignature(_msgSender());

        _burn(_msgSender(), id, 1);
        supply[id] --;
        verified[_msgSender()] = false;
    }

    /**
     * @notice returns bytes32 hash of burn function
     */
    function burnHash(address from, uint256 id, uint256 _nonce) public view virtual availIds returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(BURN_TYPEHASH, from, id, _nonce)));
    }

    /**
     * @notice transfer business token from `from` to `to`
     * 
     * Requirements:
     * only Business Token is transferrable
     * 2 signatures are needed to transfer token
     * a valid first `signature` from assignee is needed
     * a valid second `signature` from manager of assignee is needed
     * 
     * Emits a {TransferSingle} - check ERC1155
     */


    function transferBusiness(address from, address to, bytes[] memory signatures) public virtual override NotBlacklisted whenNotPaused {
        require(signatures.length == 2, 'Owner and manager signatures are needed');

        bytes32 txHash = keccak256(abi.encode(TRANSFERBUSINESS_TYPEHASH, from, to, _incrementNonce(_msgSender())));
        bytes32 hash = _hashTypedDataV4(txHash);

        address assignee;
        address manager;

        for(uint i = 0; i < signatures.length; i++) {
            bytes memory signature = signatures[i];
            if(i == 0) {
                require(verifySignature(_msgSender(), hash, signature), 'invalid owner signature');
                assignee = _msgSender();
            } else {
                require(
                    isManager(_msgSender(), assignee) && 
                    SignatureCheckerUpgradeable.isValidSignatureNow(_msgSender(), hash, signature), 
                    'invalid manager siganture'
                );
                manager = _msgSender();
            }
        }
        _safeTransferFrom(from, to, 1, 1, '');
    }

    function verifySignature(address signer, bytes32 txHash, bytes memory signature) public view virtual returns(bool) {
        return isAssignee(signer) && SignatureCheckerUpgradeable.isValidSignatureNow(signer, txHash, signature);
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

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner whenPaused {
        require(AddressUpgradeable.isContract(newImplementation), 'new implementation not contract');
    }
}
