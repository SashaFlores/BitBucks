//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17 <0.9.0;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

// solhint-disable-next-line contract-name-camelcase
contract IDToken is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, UUPSUpgradeable, PausableUpgradeable {

    using AddressUpgradeable for address;

    uint256[5] private availIds;
    mapping(uint256 => uint256) private supply;
    mapping(address => uint256) private nonces;


    /**
     * constant varaibles - non storage variables
     */
    bytes32 private constant UPGRADER_ROLE = keccak256(abi.encodePacked('UPGRADER_ROLE'));
    bytes32 private constant MINTER_ROLE = keccak256(abi.encodePacked('MINTER_ROLE'));

    uint256 public constant BUSINESS = 1;
    uint256 public constant US_PERSONA = 2;
    uint256 public constant INT_PERSONA = 3;
    uint256 public constant US_INVERSTOR = 4;
    uint256 public constant INT_INVESTOR = 5;


    // solhint-disable-next-line func-name-mixedcase
    function __IDToken_init(address upgrader, string memory uri_) external initializer virtual {
        _nonZeroAddress(_msgSender());
        _nonZeroAddress(upgrader);
        __ERC1155_init(uri_);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();

        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(UPGRADER_ROLE, DEFAULT_ADMIN_ROLE);


        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(UPGRADER_ROLE, upgrader);
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

    function totalSupply(uint256 id) public view virtual returns(uint256) {
        return supply[id];
    }

    function pauseOps() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(UPGRADER_ROLE, _msgSender()), 'missing role');
        _pause();
    }

    function unpauseOps() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(UPGRADER_ROLE, _msgSender()), 'missing role');
        _unpause();
    }

    function exists(uint256 id) external view virtual returns(bool) {
        return IDToken.totalSupply(id) > 0;
    }

    function updateURI(string memory uri_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setURI(uri_);
    }

    function grantMinterRole(address minter, uint256 id) public virtual onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused returns(bool) {
        _nonZeroAddress(minter);
        _availIds(id);
        if(balanceOf(minter, id) == 0) {
            _grantRole(MINTER_ROLE, minter);
        } else {
            revert('token either set or minted');      
        } 
        return true;
    }

    function mint(uint256 id) public virtual onlyRole(MINTER_ROLE) {
        require(grantMinterRole(_msgSender(), id), 'unauthorized token id');
        supply[id] ++;
        _mint(_msgSender(), id, 1, '');
    }

    function burn(uint256 id) public virtual onlyRole(MINTER_ROLE) whenNotPaused {
        _availIds(id);
        _burn(_msgSender(), id, 1);
        supply[id] --;
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
        require(from == address(0) && to != address(0) || from != address(0) && to == address(0), 'transfer is not allowed');
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {
        _nonZeroAddress(newImplementation);
        require(AddressUpgradeable.isContract(newImplementation), 'new implementation not contract');
    }


    function _availIds(uint256 id) private view {
        require(id <= availIds.length, 'unavailable id yet');
    }

    function _nonZeroAddress(address _address) private pure {
        require(_address != address(0), 'address zero unauthorized');
    }

}
