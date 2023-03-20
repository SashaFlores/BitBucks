# BitBucks
The aim of this project is to tokenize everything that worth value, identify individuals and enterprises, act as a proof of ownership, split payment, or even track medical records.

## *Dependencies:*

* *Node v18.13.0*
* *Ethers.js*
* *hardhat-deploy*
* *hardhat-deploy-ethers*
* *hardhat-chai-matchers*
* *hardhat-gas-reporter*
* *hardhat-solhint*
* *hardhat-network-helpers*
* *prettier-plugin-solidity*
* *Solidity Coverage*
* *MythX*
* *Slither*
* *hardhat-etherscan*

## *Work In Progress:*

### *Testing Completed Contracts*
### *Other Contracts*

## *Contracts Completed:*
### *IDToken:*

*identify yourself or your business from a range of a predetermined identities*

*contract accepts EOA & other contracts as owners, admins will send off-chain cryptographic messages to prospective token minters with a deadline to mint their tokens & verify their signatures off-chain*

*Contract can verify signatures of ECDSA from EOA and of ERC1271 from other contracts*

### *Stable Token 'BitBucks':*  

*Allows authorized minters to mint the exact allowance determined by assigned manager, Currently accepts only cash deposits.*

### *Manager Contract:*
*Module implemented by any child contract to tailor duties of each manager responsible for array of assignees. the contract deployer can assign an assignee to a manager, change manager, remove assignee, or remove manager. In the child contract you can specify manager duties as you may see fit your needs.*

### *Blacklist Contract:*

*A light module implemented by any child contracts to blacklist and lift from list accounts with red flags*

## *To Run What have been achieved so far after cloning the repository*

* *To install dependencies:*

        npm i

* *To deploy:*

    - *default network: hardhat*
    - *Named Accounts: based on your own set of keys*
    - *chosen testnet: 'sepolia'*

            npx hardhat deploy


    - *OR*

            npx hardhat deploy --network networkName

* *To Test:*

        npx hardhat test


* *To Test a specific test block or tag*

        npx hardhat test --grep 'test tag'


