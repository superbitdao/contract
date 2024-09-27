const { ethers, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function deployAllContracts() {
    const contractFolder = "./contracts/nfts"; 
    const deployedContractAddresses = [];

    const files = fs.readdirSync(contractFolder);
    
    for (const file of files) {
        if (file.endsWith(".sol")) {
            const contractName = path.basename(file, ".sol");
            console.log(`Deploying contract: ${contractName}`);

            const Contract = await ethers.getContractFactory(contractName);

            // If you want to deploy an upgradable contract, you can use the following code instead:
            // const Contract = await upgrades.deployProxy(await ethers.getContractFactory(contractName));

            const contract = await Contract.deploy();
            await contract.deployed();

            const contractAddress = contract.address;
            console.log(`Contract ${contractName} address: ${contractAddress}`);
            deployedContractAddresses.push({ contractName, contractAddress });
        }
    }

    return deployedContractAddresses;
}

async function main() {
    const deployedAddresses = await deployAllContracts();

    console.log("All contracts deployed:");
    deployedAddresses.forEach(({ contractName, contractAddress }) => {
        console.log(`Contract ${contractName} address: ${contractAddress}`);
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
