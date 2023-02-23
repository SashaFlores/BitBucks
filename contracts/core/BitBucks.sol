//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import './Manager.sol';
import './interfaces/IBitBucks.sol';
import './interfaces/IDTokenInterface.sol';
import './Blacklist.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';


/**
 * @title BitBucks
 * @author Sasha Flores
 * @dev By inheriting `MinterManager` contracrt, deployer `owner`
 * assigns `manager` to minter` & `manager` set `allowance` for
 * each `minter` that will have to mint the exact same `allowance
 * set by manager. `minter` has to be verified prior to `mint`
 */
contract BitBucks is 
    Initializable,
    IBitBucks,
    Manager,
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

    /**
     * @param idContract address, `IDToken` contract address
     */

    function __BitBucks_init(address idContract) public virtual override initializer {
        __ERC20_init('BitBucks', 'BITS');
        __Manager_init();
        __Blacklist_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        ID = IDTokenInterface(idContract);
    }

    /**
     * @notice assigned `manager` initially `setAllowance` of `minter`
     * 
     * Requirements:
     * - accessible by `onlyManager` assigned to `minter`by `owner`
     * - contract isnot paused
     * - `minter` isnot blacklisted
     * - non zero address `minter`
     * 
     * Emits {MintAllowance} event - check IBitBucks
     */
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

    /**
     * @notice assigned `manager` increment allowance by amount `increase` for `minter`
     * 
     * Requirements:
     * - accessible by `onlyManager` assigned to `minter`by `owner`
     * - contract isnot paused
     * - `minter` isnot blacklisted
     * - non zero address `minter`
     * 
     * Emits {AllowanceIncreased} event - check IBitBucks
     */
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

    /**
     * @notice assigned `manager` decrement allowance by amount `decrease` for `minter`
     * 
     * Requirements:
     * - accessible by `onlyManager` assigned to `minter`by `owner`
     * - contract isnot paused
     * - `minter` isnot blacklisted
     * - non zero address `minter`
     * - current `allowance` exceeds `decrease` amount or 
     *   revert with `BitBucks_ExceedsBalance`
     * 
     * Emits {AllowanceDecreased} event - check IBitBucks
     */
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

    /**
     * @notice minter can `mint` to `to` of the exact `amount`
     * assigned by manager, to can be account or smart contract
     * 
     * Requirements:
     * - caller is an authorized `minter` with valid `IDToken` & `to`
     *   is non zero address, otherwise function revert `BitBucks_ZeroAddress_or_unverified`
     * - contract isnot paused
     * - `minter` isnot blacklisted 
     * - `amount` is the same as `allowance` or reverts
     * 
     * Emits {Mint} event - check IBitBucks
     */
    function mint(address to, uint256 amount) public virtual override NotBlacklisted nonReentrant whenNotPaused {
        _notMinter(_msgSender());
        if(to == address(0) || !ID.isVerified(_msgSender())) 
            revert BitBucks_ZeroAddress_or_unverified();
        
        uint256 toMint = mintAllowances[_msgSender()];
        require(toMint == amount, 'BitBucks: mint exact allowance');
        unchecked {
            mintAllowances[_msgSender()] = toMint - amount;
        }
        _mint(to, amount);
        emit Mint(_msgSender(), to, amount);
    }

    /**
     * @notice returns `minterAllowance` of `minter` 
     */
    function minterAllowance(address minter) external view virtual override returns(uint256) {
        return mintAllowances[minter];
    }


    /**
     * @notice destory `burn` `amount` from `from`
     * accessible only by manager assigned to `from`
     * 
     * Requirements:
     * - caller is an authorized `minter` with valid `IDToken` & `to`
     *   is non zero address, otherwise function revert `BitBucks_ZeroAddress_or_unverified`
     * - contract isnot paused
     * - `minter` isnot blacklisted 
     * - `amount` is the same as `allowance` or reverts
     * 
     * Emits {Mint} event - check IBitBucks
     */
    function burn(address from, uint256 amount) public virtual override onlyManager(_msgSender(), from) {
        _burn(from, amount);
        emit Burn(_msgSender(), from, amount);
    }

    function pauseOps() external virtual override onlyOwner{
        _pause();
    }

    function unpauseOps() external virtual override onlyOwner {
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
        if(!isAssignee(minter)) {
            revert BitBucks_NonExistMinter();
        }
    }
}