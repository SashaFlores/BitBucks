//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

interface IBitBucks {
    
    event MintAllowance(address indexed caller, address indexed minter, uint256 amount);

    event AllowanceIncreased(address indexed caller, address indexed minter, uint256 increasedby, uint256 newAllowance);

    event AllowanceDecreased(address indexed caller, address indexed minter, uint256 decreasedby, uint256 newAllowance);

    event Mint(address indexed executor, address to, uint256 amount);
    
    event Burn(address executor, address from, uint256 amount);

    event MinterRemoved(address caller, address minter);

    error BitBucks_ExceedsBalance(uint256 balance, uint256 decrementAmount);

    error BitBucks_ZeroAddress_or_unverified();

    error BitBucks_NonExistMinter();

    function __BitBucks_init(address idContract) external;

    function setAllowance(address minter, uint256 allowance) external;

    function incrementAllowance(address minter, uint256 increase) external;

    function decrementAllowance(address minter, uint256 decrease) external;

    function mint(address safe, uint256 amount) external;

    function minterAllowance(address minter) external view returns(uint256);

    function burn(address from, uint256 amount) external;

    function pauseOps() external;

    function unpauseOps() external;
}