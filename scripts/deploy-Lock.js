// scripts/deploy-contract.js
const { ethers } = require("hardhat");

async function main() {
    // 获取部署者的地址
    const [deployer] = await ethers.getSigners();

    // 部署合约需要的参数 - 三个地址
    const sbd = "0xaF25e5424F767779612EB661466973F8d3C814C0"; // 替换为实际地址
    const svt = "0xC63595DBE3dC5B8727f69C64d93990c510cf5AB0"; // 替换为实际地址
    const srt = "0x4B25792EBA80f4e0D3433E6684537ac9f9b7aD9b"; // 替换为实际地址

    console.log("Deploying contract with deployer address:", deployer.address);
    console.log("sbd:", sbd);
    console.log("svt:", svt);
    console.log("srt:", srt);

    // 部署合约
    const Contract = await ethers.getContractFactory("Lock"); // 替换为你的合约名称
    const contract = await Contract.deploy(sbd, svt, srt);

    // 等待合约部署完成
     await contract.waitForDeployment();

  

    console.log("Contract address:", await contract.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });