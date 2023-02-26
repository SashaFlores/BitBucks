//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import '../IDToken.sol';


contract IDTokenV2 is IDToken {

    function version() public pure virtual override returns(string memory) {
        return '2.0.0';
    }

}