// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract SVTToken is ERC20, ERC20Permit, ERC20Votes,Ownable {
    using SafeMath for uint256;
    mapping(address => bool) public powerContracts;
    bool public launched;
    constructor() ERC20("Super Vote Token", "SVT") ERC20Permit("SVT") {
        launched = false;
    }

    function mint(address account,uint256 amount) external {
        require(powerContracts[msg.sender],"No Permission");
        _mint(account, amount);
    }

    function burn(address account,uint256 amount) external {
        require(powerContracts[msg.sender],"No Permission");
        _burn(account, amount);
    }
    function setPowerContract(address sender,bool status) external onlyOwner{
        powerContracts[sender] = status;
    }
    function launch() external onlyOwner{
        launched = !launched;
    }
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal  override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
    function _transfer(address from, address to, uint256 amount) internal override {
        require(launched,"Transaction not opened");
        super._transfer(from,to,amount);
    }
}