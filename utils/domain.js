const EIP_DOMAIN = {
    EIP712Domain: [
        {type: 'string', name: 'name'},
        {type: 'string', name: 'version'},
        {type: 'uint256', name: 'chainId'},
        {tye: 'address', name: 'verifyingContract'}
    ]
}

const MINT_TYPEHASH = {
    MINT: [
        {type: 'uint256', name: id},
        {type: 'uint256', name: deadline},
        {type: 'uint256', name: nonce}
    ]
}

const BURN_TYPEHASH = {
    BURN: [
        {type: 'address', name: from},
        {type: 'uint256', name: id},
        {type: 'uint256', name: nonce},
    ]
}
const TRANSFERBUSINESS_TYPEHASH = {
    TransferBusiness: [
        {type: 'address', name: from},
        {type: 'address', name: to},
        {type: 'uint256', name: nonce},
    ]
}



module.exports = { EIP_DOMAIN, MINT_TYPEHASH, BURN_TYPEHASH, TRANSFERBUSINESS_TYPEHASH }