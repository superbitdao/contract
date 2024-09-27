//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
interface ISVT{
    function mint(address _to, uint256 _amount)external;
    function burn(address _to, uint256 _amount) external;
}
contract ogLock is Ownable {

using SafeMath for uint256;
    struct LockInfo{
        address user;
        uint256 amount;
        uint256 lockBlock;
        uint256 startTime;
    }
    IERC20 sbd;
    
    uint256 withdrawId;
    address public  svt;
    uint256 public oneYear;
    mapping(address => bool) public allowAddr;
    mapping(address => LockInfo[]) public userLockInfos;
    mapping(address => uint256 ) public notExtracted;
    event withdrawRecord(uint256 id, address user, uint256 amount,uint256 burn );
constructor (){
        oneYear = 31536000;
        withdrawId = 1;

}
function setSbd(IERC20 _sbd) public onlyOwner {
    sbd = _sbd;
}
function setSvt(address _addr) public onlyOwner {
    svt = _addr;
}
    function setAllowAddr(address _addr, bool _set) public onlyOwner {
         allowAddr[_addr] = _set;
    }
    function lock(address _user,uint256 _svtAmount) external {
        require(allowAddr[msg.sender]);
            LockInfo memory _lockInfo = LockInfo({
            user:_user,
            amount:_svtAmount,
            lockBlock:block.number,
            startTime:block.timestamp
        });
        userLockInfos[_user].push(_lockInfo);

    }
        function getUserCanClaim(address _user) public view returns(uint256) {
        uint256 total = 0;
        for(uint256 i = 0 ; i<getUserLockLength(_user);i++){
            total = total.add(userLockInfos[_user][i].amount.mul(block.number.sub(userLockInfos[_user][i].lockBlock)).div(oneYear));
        }
        return total.add(notExtracted[_user]);
    }
    function Claim(uint256 amount) public  {
        require(getUserCanClaim(msg.sender) >= amount && getContractSbdBalance() >= amount);
        require(amount > 0);
        uint256 totalTransfer = 0;
        if(notExtracted[msg.sender] >=  amount){
            notExtracted[msg.sender] = notExtracted[msg.sender].sub(amount);
            sbd.transfer(msg.sender, amount);
            ISVT(svt).burn(msg.sender,amount);
            emit withdrawRecord(withdrawId, msg.sender, amount,amount);
            return;
        }
        if(notExtracted[msg.sender] <  amount && notExtracted[msg.sender] > 0){
            sbd.transfer(msg.sender, notExtracted[msg.sender]);
            ISVT(svt).burn(msg.sender,notExtracted[msg.sender]);
            notExtracted[msg.sender] = 0;
            amount = amount.sub(notExtracted[msg.sender]);
        }
        for(uint256 i = 0 ; i<getUserLockLength(msg.sender);i++){
            if(userLockInfos[msg.sender][i].amount == 0 ){
                continue;
            }
            uint256 claimAmount =  userLockInfos[msg.sender][i].amount.mul(block.number.sub(userLockInfos[msg.sender][i].lockBlock)).div(oneYear);
            totalTransfer = totalTransfer.add(claimAmount);
            userLockInfos[msg.sender][i].amount = userLockInfos[msg.sender][i].amount.sub(claimAmount);
            userLockInfos[msg.sender][i].lockBlock = block.number;
            if(totalTransfer >= amount){
                sbd.transfer(msg.sender, amount);
                ISVT(svt).burn(msg.sender,amount);
                amount = amount.add(notExtracted[msg.sender]);
                notExtracted[msg.sender] = totalTransfer.sub(amount);
                emit withdrawRecord(withdrawId, msg.sender, amount,amount);
                withdrawId++;
                break;
        }
         
    }
  
    }
    function getContractSbdBalance() public view returns(uint256) {
        return sbd.balanceOf(address(this));
    }
    function getUserLockLength(address _user) public view returns(uint256) {
        return userLockInfos[_user].length;
    } 
}