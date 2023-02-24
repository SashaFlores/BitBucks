const DOMAIN = [
    {type: 'string', name: 'name'},
    {type: 'string', name: 'version'},
    {type: 'uint256', name: 'chainId'},
    {tye: 'address', name: 'verifyingContract'}
]

const MINT = [
    {type: 'uint256', name: id},
    {type: 'uint256', name: deadline},
    {type: 'uint256', name: nonce}
]

const BURN = [
    {type: 'address', name: from},
    {type: 'uint256', name: id},
    {type: 'uint256', name: nonce},
]
const TRANSFER_BUSINESS = [
    {type: 'address', name: from},
    {type: 'address', name: to},
    {type: 'uint256', name: nonce},
]



module.exports = { DOMAIN, MINT, BURN, TRANSFER_BUSINESS }