const { run } = require('hardhat')

const verify = async (contractAddress, args) => {
    log('-----Verifying Contract-----')
    try {
        await run('verify:verify', {
            address: contractAddress,
            constructorArguments: args
        })
    } catch(error) {
        if (error.message.toLowerCase().includes('already verified')) {
            log('Already Verified')
        } else {
            log(error)
        }
    }
}
module.exports = { verify }