//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import '../IDToken.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract IDTokenV2 is Initializable, IDToken {


    function __IDTokenV2_init(string memory uri) public initializer {
        __IDToken_init(msg.sender, msg.sender, uri);
    }

    function version() public pure virtual override returns(string memory) {
        return '2.0.0';
    }

}