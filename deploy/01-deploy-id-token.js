const { network, ethers } = require('hardhat')
//const { URI } = require('constants');


module.exports = async ({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments;
    const { admin, upgrader } = await getNamedAccounts();
    console.log({namedAccounts: await getNamedAccounts()})

    log(`-----Preparing Contracts for Deployments -------`)
    
    // deploy Imp 'IDToken' to use the address to invoke proxy
    const deployImp = await deploy('Imp', {
        contract: 'IDToken',
        from: admin,
        log: true,
    })

    log(`01- Implementation Deployed at ${deployImp.address}`)
    
    const Implementation = await ethers.getContractAt('IDToken', deployImp.address)
  
    // https://docs.ethers.org/v5/api/utils/abi/interface/
    const encodedFuncData = await Implementation.interface.encodeFunctionData('__IDToken_init', [upgrader, 'http://bafybeihqp5dcnhnspwhs3fqh4tmzweu6nw33iukx6i4sqnv4vwed3zuwc4.ipfs.localhost:8080/{id}.json'])
    log(`encoded function data from Impl. constructor is: ${encodedFuncData}`)

    const proxy = await deploy('Proxy', {
        contract: 'ERC1967Proxy',
        from: upgrader,
        args:[Implementation.address, encodedFuncData],
        log: true,
        //waitConfirmations: network.name.blockConfirmations || 1,
    })
    console.log(`Proxy address is ${proxy.address}`)
    
    const idToken = Implementation.attach(proxy.address)
    log(`${idToken.address}`)

    const name = await idToken.name()
    log(`ID Token name is ${name}`)

    const uri = await idToken.uri(1)
    log(`${uri}`)
}
module.exports.tags = ['Imp', 'all', 'Proxy']

