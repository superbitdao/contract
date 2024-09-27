
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity:{
    compilers:[
      {version:"0.6.12",},
      {version: "0.8.18"}
    ]
  },
  networks: {
    bscTest: {
      chainId: 97,
      url: `https://data-seed-prebsc-1-s1.bnbchain.org:8545`,
      accounts:[""]
    },
    
  },
};
