# BitBucks
The aim of this project is to tokenize everything that worth value, identify individuals and enterprises, act as a proof of ownership, split payment, or even track medical records.

## *Dependencies:*

* *Node v18.13.0*
* *Ethers.js*
* *hardhat-deploy*
* *hardhat-deploy-ethers*
* *hardhat-chai-matchers*
* *Solidity Coverage*
* *MythX*
* *Slither*
* *hardhat-etherscan*

## *Work In Progress:*

## *IDToken:*

*identify yourself or your business from a range of a predetermined identities*

## *Stable Token 'BitBucks':*  

*It's based on segregation of duties; contract owner will assign a manager to each minter, the manager responsibility is to determine the exact amount that minter is allowed to mint, with preserving the right to the owner to audit manager &/or minter*

## *To Run What have been achieved so far after cloning the repository*

* *To install dependencies:*

        npm i

* *To deploy:*

    - *default network: hardhat*
    - *Named Accounts: based on your own set of keys*
    - *chosen test network: 'sepolia'*

            npx hardhat deploy


    - *OR*

            npx hardhat deploy --network networkName

* *To Test:*

        npx hardhat test


