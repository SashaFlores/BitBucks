const { ethers } = await import("npm:ethers@6.10.0");
const Hash = await import("npm:ipfs-only-hash@4.0.0");

const response = await Functions.makeHttpRequest({
    url: `https://api.bridgedataoutput.com/api/v2/OData/test/Property('P_5dba1fb94aa4055b9f29696f')?access_token=6baca547742c6f96a6ff71b138424f21`,
});

