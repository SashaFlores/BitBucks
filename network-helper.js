require('dotenv').config();

const developmentChains = ['hardhat', 'localDev']

const networkConfig = {

    localDev: {
        idToken: {
            admin: process.env.ADMIN,
            upgrader: 
        }
    }

}




    

module.exports = { developmentChains }