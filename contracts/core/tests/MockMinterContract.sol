//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';



/**
 * @dev refer to 'https://eips.ethereum.org/EIPS/eip-1271'
 * Example implementation of a signing contract.
 */

contract MockMinterContract is Ownable {

    constructor() {
        require(msg.sender != address(0), 'unauthorized address zero');
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view returns(bytes4) {
        if(recoverSigner(hash, signature) == owner()) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }

    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        require(signature.length == 65, 'invalid signature length');

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if(uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert('invalid `s` value');
        }
        if(v != 27 && v != 28) {
            revert('invalid `v` value');
        }

        return ecrecover(hash, v, r, s);
    }

    

}