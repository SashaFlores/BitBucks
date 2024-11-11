// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC6065 is IERC721 {

	// This event MUST emit if the asset is ever foreclosed.
	event Foreclosed(uint256 id);

	/* 
	Next getter functions return immutable data for NFT.
    These are  unique identifiers ensure the physical property in question is clear and identifiable.
    These strings must be immutable to make certain that the identity of the property can not be changed in the future.
	*/
    
    // written description of the property taken from the physical property deed
	function legalDescriptionOf(uint256 _id) external view returns (string memory);

	function addressOf(uint256 _id) external view returns (string memory);

    // the GeoJSON format of the property’s geospatial coordinates
	function geoJsonOf(uint256 _id) external view returns (string memory);

    // ID number used to identify the property by the local authority
	function parcelIdOf(uint256 _id) external view returns (string memory);

    // the legal entity that is named on the verifiable physical deed
	function legalOwnerOf(uint256 _id) external view returns (string memory);

    /*
    An immutable hash of the legal document issued by the legal entity that owns the property. 
    Upon transfer of the NFT, these legal rights are immediately enforceable by the new owner.
    For changes to the legal structure or rights and conditions with regard to the property 
    the original token must be burned and a new token with the new hash must be minted.
    */
	function operatingAgreementHashOf(uint256 _id) external view returns (bytes32);

	/*
	Next getter function returns the debt denomination token of the NFT, the amount of debt (negative debt == credit), 
    and if the underlying asset backing the NFT has been foreclosed on. 
    This should be utilized specifically for off-chain debt and required payments on the RWA asset.
	It's recommended that administrators only use a single token type to denominate the debt. 
    It's unrealistic to require integrating smart
	contracts to implement possibly unbounded tokens denominating the off-chain debt of an asset.

	If the foreclosed status == true, then the RWA can be seen as severed from the NFT. The NFT is now "unbacked" by the RWA.
	*/
	function debtOf(uint256 _id) external view returns (address debtToken, int256 debtAmt, bool foreclosed);

	// Get the managerOf an NFT. The manager can have additional rights to the NFT or RWA on or off-chain.
	function managerOf(uint256 _id) external view returns (address);
}