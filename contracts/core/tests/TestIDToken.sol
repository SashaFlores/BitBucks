//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import '../IDToken.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';



contract TestIDToken is Initializable, IDToken {

    // solhint-disable-next-line const-name-snakecase
    string public constant newURI = 'sasha.com';


    constructor() initializer {
        __Blacklist_init();
        __Manager_init();
        __ERC1155_init(newURI);
        __IDToken_init(newURI);
        __EIP712_init('TestIDToken', '0.0.0');
    }


    function version() public pure override returns(string memory) {
        return '0.0.0';
    }

    function testMint(uint256 id, uint256 deadline, bytes calldata signature) public {
        super.mint(id, deadline, signature);
    }


    function tesTransferBusiness(address from, address to, bytes[] memory signatures) public {
       super.transferBusiness(from, to, signatures);
    }

    function testBurn(address from, uint256 id, bytes calldata signature) public {
        super.burn(from, id, signature);
    }

}