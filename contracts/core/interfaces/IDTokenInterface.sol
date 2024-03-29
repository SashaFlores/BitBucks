//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

interface IDTokenInterface {

    /* solhint-disable var-name-mixedcase */
    error IDToken_IdMinted(address IdHolderAddress, uint256 id);

    error IDToken_ZeroAddress();

    error IDToken_UnavailID();

    error IDToken_invalidSignature(address signer);
    /* solhint-enable var-name-mixedcase */

    // solhint-disable-next-line func-name-mixedcase
    function __IDToken_init(string memory uri_) external;
    
    function totalSupply(uint256 id) external returns(uint256);

    function transferBusiness(address from, address to, bytes[] memory signatures) external;

    function isVerified(address account) external returns(bool);

    function signerNonce(address signer) external view returns(uint256);
    
    function mint(uint256 id, uint256 deadline, bytes calldata signature) external;

    function burn(address addr, uint256 id, bytes calldata signature) external;

    function updateURI(string memory uri_) external;

    function minted(uint256 id) external returns(bool);
}