//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract usdt is ERC20{
    constructor()ERC20("BTC","BTC"){
        _mint(msg.sender, 1000000000000*10**18);
    }
}