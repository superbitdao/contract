// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract S {
    using SafeMath for uint256 ;
    uint256 salePrice = 5;

    function receiveSbd(uint256 _usdtAmount) public view returns(uint256 ){
        uint256 divisor = salePrice.div(1000); // 将除数计算为 salePrice 的 1/1000
        return _usdtAmount.div(divisor);
    }
    function st(uint256 _a,uint256 _b)public view returns(uint256){
        return _a.div(_b);
    }
      function receiveSbd1(uint256 _usdtAmount) public view returns(uint256 ){
        return _usdtAmount/salePrice/1000;
    }
    function getaddr() public view returns(address){
        return address(0);
    }
  function getCurrentTimestamp() public view returns(uint256 ){
        return block.timestamp;
    }

}