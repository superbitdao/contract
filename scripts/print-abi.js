
const { ethers, run } = require('hardhat');

async function main() {
  // Replace 'YourContractName' with the name of your contract
  const contractName = 'NFTLock';

  // Load the contract using Hardhat's ethers library
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await Contract.deployed();

  // Get the contract's ABI
  const abi = contract.interface.format(ethers.utils.FormatTypes['full']);

  // Print the ABI
  console.log('Contract ABI:');
  console.log(JSON.stringify(abi, null, 2));
}

// Execute the script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
