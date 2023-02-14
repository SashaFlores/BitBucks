//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import './MinterManager.sol';
import './interfaces/IBitBucks.sol';
import './interfaces/IDTokenInterface.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';


contract BitBucks is 
    Initializable,
    IBitBucks,
    MinterManager,
    UUPSUpgradeable,
    ERC20Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
 {

    using AddressUpgradeable for address;

    mapping(address => uint256) private mintAllowances;
  

    string private constant _name = 'BitBucks';
    string private constant _symbol = 'AND';

  
    IDTokenInterface private ID;

    function __BitBucks_init(address idContract) public virtual override initializer {
        __ERC20_init('BitBucks', 'BITS');
        __MinterManager_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        ID = IDTokenInterface(idContract);
    }


    function setAllowance(address minter, uint256 allowance) public virtual override onlyManager(_msgSender(), minter) whenNotPaused {
        require(allowance > 0, 'BitBucks: zero allowance');
        mintAllowances[minter] = allowance;
        emit MintAllowance(_msgSender(), minter, allowance);
    }

    function increaseMintAllowance(address minter, uint256 increase) public virtual override onlyManager(_msgSender(), minter) whenNotPaused {
        require(increase > 0, 'BitBucks: new allowance is zero');
        uint256 oldAllowance = mintAllowances[minter];
        uint256 allowance = oldAllowance + increase;
        mintAllowances[minter] = allowance;
        emit AllowanceIncreased(_msgSender(), minter, increase, allowance);
    }

    function decareseMinterAllowance(address minter, uint256 decrease) public virtual override onlyManager(_msgSender(), minter) whenNotPaused {
        require(decrease > 0, 'BitBucks: decrement is zero');
        uint256 currentAllowance = mintAllowances[minter];
        if(currentAllowance >= decrease) {
            uint256 allowance = currentAllowance - decrease;
            mintAllowances[minter] = allowance;
            emit AllowanceDecreased(_msgSender(), minter, decrease, allowance);
        } else {
            revert('BitBucks: current allowance less than decreasing value');
        }
    }

    function mint(address to, uint256 amount) public virtual override nonReentrant {
        require(to != address(0), 'BitBucks: unauthorized zero address');
        require(ID.isVerified(_msgSender()), "BitBucks: unverified account");
        require(isMinter(_msgSender()), 'BitBucks: unauthorized minter');
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
        require(isMinter(minter), 'BitBucks: minter doesnot exist');
        exists[minter] = false;
        emit MinterRemoved(_msgSender(), minter);
        return isMinter(minter);
    }

    function burn(address from, uint256 amount) public virtual override onlyManager(_msgSender(), from) {
        require(amount > 0, 'BitBucks: nothing to burn');
        _burn(from, amount);
        emit Burn(_msgSender(), from, amount);
    }

    function pauseOps() public virtual override onlyOwner{
        _pause();
    }

    function unpauseOps() public virtual override onlyOwner {
        _unpause();
    } 

    function isPaused() public view virtual override returns(bool) {
       return paused();
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
}