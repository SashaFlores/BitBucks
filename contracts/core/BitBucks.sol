//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import './MinterManager.sol';
import './interfaces/IBitBucks.sol';
import './interfaces/IDTokenInterface.sol';
import './Blacklist.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';


contract BitBucks is 
    Initializable,
    IBitBucks,
    MinterManager,
    Blacklist,
    UUPSUpgradeable,
    ERC20Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
 {
    using AddressUpgradeable for address;

    mapping(address => uint256) private mintAllowances;
  

    string private constant _name = 'BitBucks';
    string private constant _symbol = 'BITS';

  
    IDTokenInterface private ID;

    function __BitBucks_init(address idContract) public virtual override initializer {
        __ERC20_init('BitBucks', 'BITS');
        __MinterManager_init();
        __Blacklist_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        ID = IDTokenInterface(idContract);
    }


    function setAllowance
    (
        address minter, 
        uint256 allowance
    ) 
    public 
    virtual 
    override 
    onlyManager(_msgSender(), minter) 
    NotBlacklisted 
    whenNotPaused 
    nonReentrant
    {
        mintAllowances[minter] = allowance;
        emit MintAllowance(_msgSender(), minter, allowance);
    }

    function incrementAllowance
    (
        address minter, 
        uint256 increase
    ) 
    public 
    virtual 
    override 
    onlyManager(_msgSender(), minter) 
    NotBlacklisted
    nonReentrant
    whenNotPaused 
    {
        uint256 oldAllowance = mintAllowances[minter];
        uint256 allowance = oldAllowance + increase;
        mintAllowances[minter] = allowance;
        emit AllowanceIncreased(_msgSender(), minter, increase, allowance);
    }

    function decrementAllowance
    (
        address minter, 
        uint256 decrease
    ) 
    public 
    virtual 
    override 
    onlyManager(_msgSender(), minter) 
    NotBlacklisted
    nonReentrant
    whenNotPaused 
    {
    
        uint256 currentAllowance = mintAllowances[minter];
        if(currentAllowance >= decrease) {
            uint256 allowance = currentAllowance - decrease;
            mintAllowances[minter] = allowance;
            emit AllowanceDecreased(_msgSender(), minter, decrease, allowance);
        } else {
            revert BitBucks_ExceedsBalance(currentAllowance, decrease);
        }
    }

    function mint(address to, uint256 amount) public virtual override NotBlacklisted nonReentrant whenNotPaused {
        _notMinter(_msgSender());
        if(to == address(0) || !ID.isVerified(_msgSender())) {
            revert BitBucks_ZeroAddress_or_unverified();
        }
        
        uint256 toMint = mintAllowances[_msgSender()];
        require(toMint == amount, 'BitBucks: mint exact allowance');
        unchecked {
            mintAllowances[_msgSender()] = toMint - amount;
        }
        _mint(to, amount);
        emit Mint(_msgSender(), to, amount);
    }

    function minterAllowance(address minter) external view virtual override returns(uint256) {
        return mintAllowances[minter];
    }

    function removeMinter(address minter) public virtual override onlyOwner whenNotPaused returns(bool) {
        _notMinter(minter);
        exists[minter] = false;
        emit MinterRemoved(_msgSender(), minter);
        return isMinter(minter);
    }

    function burn(address from, uint256 amount) public virtual override onlyManager(_msgSender(), from) {
        _burn(from, amount);
        emit Burn(_msgSender(), from, amount);
    }

    function pauseOps() public virtual override onlyOwner{
        _pause();
    }

    function unpauseOps() public virtual override onlyOwner {
        _unpause();
    } 

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), 'BitBucks: token transfer paused');
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual override {
        super._approve(owner, spender, amount);
        require(!paused(), 'BitBucks: approvals paused');
    }
    
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {
        require(AddressUpgradeable.isContract(newImplementation), 'BitBucks: new Implementation must be a contract');
        require(newImplementation != address(0), 'BitBucks: zero address error');
    }

    function _notMinter(address minter) private view {
        if(!isMinter(minter)) {
            revert BitBucks_NonExistMinter();
        }
    }
}