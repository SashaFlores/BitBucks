//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


interface IBitRealty {


    //emitted when `callerAddress` modify tokenURI of `tokenId` to `newURI`
    event TokenURIModified(uint256 indexed tokenId, string newURI, address callerAddress);

    //emitted when `tokenId` change metadata to `newName` & `newSymbol`
    event MetadataChanged(uint256 indexed tokenId, string newName, string newSymbol);

    //emitted when `tokenId` is burned by `callerAddress`
    event Burnedtoken(uint256 tokenId, address callerAddress);

    function __BitRealty_init
    (      
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenURI,
        address to, 
        string memory state, 
        string memory city, 
        uint256 zipcode
    ) external;


    function tokenURI(uint256 estateTokenId) external view returns(string memory);

    function name(uint256 tokenId) external view returns(string memory);

    function symbol(uint256 tokenId) external view returns(string memory);

    function totalSupply() external view returns(uint256);
    
    function modifyTokenURI(uint256 tokenId, string memory uri) external;

    function modifyTokenMetadata(uint256 tokenId, string calldata name, string calldata symbol) external;

    function tokenLocation(uint256 tokenId) external view returns(string memory, string memory, uint256);

    function burn(uint256 tokenId) external;

}