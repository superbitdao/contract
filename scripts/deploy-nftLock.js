// scripts/deploy-contract.js
const fs = require('fs'); // 引入文件系统模块
const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
    // 获取部署者的地址
    const [deployer] = await ethers.getSigners();

    // 部署合约需要的参数 - 三个地址
    const srt = "0x4B25792EBA80f4e0D3433E6684537ac9f9b7aD9b"; // 替换为实际地址
    const supNft = "0x8cdE6d281d6D4e4bd215Cc23A1862659e0C44Ad7";
    const bigNft = "0xdA4e04f6362A1f8262A279A5D9a1BaADA355B7f2";
    const smallNft = "0x9B26c2086504BD95B0eEd720648b6616592fC21D";
    console.log("Deploying contract with deployer address:", deployer.address);
    console.log("srt:", srt);
    console.log("supNft:", supNft);
    console.log("bigNft:", bigNft);
    console.log("smallNft:", smallNft);

    // 部署合约
    const Contract = await ethers.getContractFactory("NFTLock"); // 替换为你的合约名称
    const contract = await Contract.deploy(srt, supNft, bigNft,smallNft,{
        gasLimit: 7000000, // 根据需要调整燃气限制
      });

    // 等待合约部署完成
     await contract.waitForDeployment();

    console.log("Contract address:", await contract.getAddress());
    const abi = Contract.interface.format(hre.ethers.utils.FormatTypes['full']);

    fs.writeFileSync('NFTLock.json', abi);

    console.log('YourContract ABI has been saved to YourContractABI.json');
  
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });