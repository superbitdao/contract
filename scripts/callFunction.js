// batchCallContracts.js

async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log(`Calling contracts with address: ${deployer.address}`);
  
    const YourContract = await ethers.getContractFactory("FireDaoRedOGNode");
  
    const methodName = "setAllowAddr";
  
    const contractAddresses =["0x52DD5C3b4775EB49E97Bf5B4833Fc8E25e26f7B0","0xe2B3114A69535ac91cd6b494C128f312F8a9B87c","0x452EBeE15C193068308116AC0EDeC36cb2f28CbB","0x86e098686FE87246e6FA75B843F712fc2f300b0B","0x051072af73212d82931B0820E1d766D0D8bF4372","0x0585Be074e8599077F7B397F06AA6f991a6CC4d3","0x3a23D495FBe24Ea3026b6A9D81d840913daDd8DB"];
  
    for (const contractAddress of contractAddresses) {
      console.log(`Calling ${methodName} on contract at address: ${contractAddress}...`);
  
      const yourContractInstance = await YourContract.attach(contractAddress);
      const result = await yourContractInstance[methodName]("0x454ccf823A38bc90Db4877A570ea8F864776A9e4",true);
  
      console.log(`${methodName} result from ${contractAddress}: ${result}`);
    }
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  