//SPDX-License-Identifier: UNLICENSED
// File: contracts/libraries/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract NFTLock is Ownable,ReentrancyGuard{ 
    using SafeMath for uint256;
    struct lockInfo{
        uint256 tokenId;
        address user;
        address nft;
        uint256 power;
        uint256 startTimeBlock;
    }
    uint256[] public reward;
    uint256[] public rewardTime;
    uint256[] public startRewardTime;

    uint public intervalTime = 5;
    uint public day = 86400;
    uint256 public blockTime;
    address public srt;
    address public supNft;
    address public bigNft;
    address public smallNft;
    uint256 public totalPower;
    uint256 public SupNftAmount;
    uint256 public BigNftAmount;
    uint256 public SmallNftAmount;
    lockInfo[] public lockInfos;
    mapping(address => uint256) public  userSupNftAmount;
    mapping(address => uint256) public userBigNftAmount;
    mapping(address =>uint256) public userSmallNftAmount;
    mapping(address => uint256 ) public lastRewardBlock;
    mapping(address => uint256 ) public accSrtPerShare;
    mapping(address => uint256 ) public userPower;
    mapping(address => uint256 ) public rewardDebt;
    mapping(address => uint256 ) public nftPower;
    mapping(address => lockInfo[]) public userLockInfos;
    mapping(address => uint256 ) public userTotalLock;
    mapping(uint256 => uint256 ) public adminDepositBlock;

    event lockRecord(address user, string  nft, uint256 tokenId, uint256 power);
    event unLockRecord(address user, string nft, uint256 tokenId, uint256 power);
    event claimSrtRecord(address user, uint256 amount);
    event adminDeposit(address admin,address token, uint256 amount);
    event adminWithdraw(address admin,address token, uint256 amount);
    constructor(address _srt,address _supNft, address _bigNft, address _smallNft) {
        nftPower[_supNft] = 10;
        nftPower[_bigNft] = 3;
        nftPower[_smallNft] = 1;
        srt = _srt;
        supNft = _supNft;
        bigNft = _bigNft;
        smallNft = _smallNft;
    }
    function setSrt(address _srt) public onlyOwner {
        srt = _srt;
    }
    function setPower(address _node, uint256 _power) public onlyOwner{
        nftPower[_node] = _power;
    }
    function deposit(uint256 _amount,uint256 _rewardTime) public onlyOwner {
        uint256 currentTime = block.timestamp;
        reward.push(_amount);
        rewardTime.push(_rewardTime.mul(day));
        startRewardTime.push(currentTime);
        adminDepositBlock[reward.length] = block.number;

        TransferHelper.safeTransferFrom(srt, msg.sender,address(this),_amount);
        emit adminDeposit(msg.sender, srt,_amount);

    }
    function backToken(address _token, uint256 _amount) public onlyOwner{
        require(IERC20(_token).balanceOf(address(this))>_amount,"Insufficient balance of withdrawn tokens");
        IERC20(_token).transfer(msg.sender, _amount);
        emit adminWithdraw(msg.sender, _token, _amount);

    }
    function getRewardLength() public view returns(uint256 ){
        return reward.length;
    }
      function getMultiplier(uint256 _from, uint256 _to,uint256 _i) public view returns (uint256) {
        uint256 _rewardTime = (startRewardTime[_i].add(rewardTime[_i])).div(intervalTime);
        if(_from ==0  && _to > startRewardTime[_i] && _to < _rewardTime ) {
            return _to.sub(startRewardTime[_i]);
        }
        if (_to > _from) {
            return _to.sub(_from);
        } else if(_to >= _rewardTime && _from < _rewardTime){
            return _rewardTime.sub(_from);
        }
      else{
            return 0;
        }
      
    }
    function updatePower(address _user) public nonReentrant {

        if(block.number <= lastRewardBlock[_user] || getContractSrtBalance() == 0 ) {
            return;
        }
        if(totalPower == 0  ){
            lastRewardBlock[_user] = block.number;
            return;
        }
        for(uint256 i = 0; i<reward.length;i++){

        uint256 multiplier = getMultiplier(lastRewardBlock[_user], block.number,i);
        uint256 srtReward = multiplier.mul(getOneBlockReward(i));
        accSrtPerShare[_user] = accSrtPerShare[_user].add(srtReward.mul(1e12).div(totalPower));
        }
        lastRewardBlock[_user] = block.number;
        }

    function lockNft(uint256 _nft,uint256 _tokenId) public nonReentrant{
        require(_nft <= 3 && _nft != 0,'input error');
        updatePower(msg.sender);
        if(userPower[msg.sender] > 0 ){
            uint256 pending = userPower[msg.sender].mul(accSrtPerShare[msg.sender]).div(1e12).sub(rewardDebt[msg.sender]);
            safeSrtTransfer(msg.sender, pending);
        }
        rewardDebt[msg.sender] = userPower[msg.sender].mul(accSrtPerShare[msg.sender]).div(1e12);
        if(_nft == 1) {
            require(IERC721(smallNft).balanceOf(msg.sender) != 0,"You do not have a small node NFT");
            IERC721(smallNft).transferFrom(msg.sender, address(this),_tokenId);
            lockInfo memory _info = lockInfo({
                tokenId: _tokenId,
                user: msg.sender,
                nft:smallNft,
                power: nftPower[smallNft],
                startTimeBlock:block.number
            });
            lockInfos.push(_info);
            userLockInfos[msg.sender].push(_info);
            userPower[msg.sender] = userPower[msg.sender].add(nftPower[smallNft]);
            userSmallNftAmount[msg.sender] = userSmallNftAmount[msg.sender].add(1);
            SmallNftAmount = SmallNftAmount.add(1);
            totalPower = totalPower.add(nftPower[smallNft]);
            emit lockRecord(msg.sender, "SMALL_Node_NFT",_tokenId, nftPower[smallNft]);
        }else if(_nft == 2) {
            require(IERC721(bigNft).balanceOf(msg.sender) != 0,"You do not have a small node NFT");
            IERC721(bigNft).transferFrom(msg.sender, address(this),_tokenId);
            lockInfo memory _info = lockInfo({
                tokenId: _tokenId,
                user: msg.sender,
                nft : bigNft,
                power: nftPower[bigNft],
                startTimeBlock:block.number
            });
            lockInfos.push(_info);

            userLockInfos[msg.sender].push(_info);
            userPower[msg.sender] = userPower[msg.sender].add(nftPower[bigNft]);
            userBigNftAmount[msg.sender] = userBigNftAmount[msg.sender].add(1);
            BigNftAmount = BigNftAmount.add(1);
            totalPower = totalPower.add(nftPower[bigNft]);
            emit lockRecord(msg.sender, "BIG_NODE_NFT",_tokenId, nftPower[bigNft]);

        }else if(_nft ==3){
            require(IERC721(supNft).balanceOf(msg.sender) != 0,"You do not have a small node NFT");
            IERC721(supNft).transferFrom(msg.sender, address(this),_tokenId);
            lockInfo memory _info = lockInfo({
                tokenId: _tokenId,
                user: msg.sender,
                nft:supNft,
                power: nftPower[supNft],
                startTimeBlock:block.number
            });
            lockInfos.push(_info);

            userLockInfos[msg.sender].push(_info);
            totalPower = totalPower.add(nftPower[supNft]);
            userSupNftAmount[msg.sender] = userSupNftAmount[msg.sender].add(1);
            userPower[msg.sender] = userPower[msg.sender].add(nftPower[supNft]);
            SupNftAmount = SupNftAmount.add(1);
            emit lockRecord(msg.sender, "SUP_NODE_NFT",_tokenId, nftPower[supNft]);
        }else {
            revert("input error");
        }
        userTotalLock[msg.sender] = userTotalLock[msg.sender].add(1);

    }
    function getLockInfosLength() public view returns(uint256){
        return lockInfos.length;
    } 
    function getUserLockInfosLength(address _user) public view returns(uint256 ){
        return userLockInfos[_user].length;
    }
    function getOneBlockReward(uint256 _rewardId) public view returns(uint256) {
        return reward[_rewardId].div(rewardTime[_rewardId].div(intervalTime));
    }
 
    function pendingSrt(address _user) external view returns (uint256) {
        uint256 accSrtPerShareE = accSrtPerShare[_user];
        uint256 debet = rewardDebt[_user];
        uint256 _userPower = userPower[_user];
        if(_userPower == 0) {
            return 0;
        }
        for(uint256 i = 0 ; i <reward.length;i++ ){
        uint256 powerSupply = totalPower;
        if (block.number > lastRewardBlock[_user] && powerSupply != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock[_user], block.number, i);
            uint256 srtReward = multiplier.mul(getOneBlockReward(i));
            accSrtPerShareE = accSrtPerShareE.add(srtReward.mul(1e12).div(powerSupply));
        }
        }
            return _userPower.mul(accSrtPerShareE).div(1e12).sub(debet);
       
    }
    function ClaimSrt() public nonReentrant {
          updatePower(msg.sender);
            uint256 pending = userPower[msg.sender].mul(accSrtPerShare[msg.sender]).div(1e12).sub(rewardDebt[msg.sender]);
            safeSrtTransfer(msg.sender, pending);
            rewardDebt[msg.sender] = userPower[msg.sender].mul(accSrtPerShare[msg.sender]).div(1e12);
        emit claimSrtRecord(msg.sender, pending);
    }
    function deleteNft(address _user,uint256 _order) internal{
        userLockInfos[_user][_order] = userLockInfos[_user][userLockInfos[_user].length - 1];
        userLockInfos[_user].pop();
    }

    function withdrawNft(uint256 _nftClass , uint256 _tokenId ) public  nonReentrant{
        uint256 bufferStatus = 0;
        updatePower(msg.sender);
            uint256 pending = userPower[msg.sender].mul(accSrtPerShare[msg.sender]).div(1e12).sub(rewardDebt[msg.sender]);
            safeSrtTransfer(msg.sender, pending);
            rewardDebt[msg.sender] = userPower[msg.sender].mul(accSrtPerShare[msg.sender]).div(1e12);

        if(_nftClass == 1){
            require(IERC721(smallNft).balanceOf(address(this)) != 0 ," do not have a small node NFT");
            for(uint256 i =0 ; i < userLockInfos[msg.sender].length; i++){
                require(
                smallNft == userLockInfos[msg.sender][i].nft &&
                _tokenId == userLockInfos[msg.sender][i].tokenId ,
                "You don t have this small Node NFT");
                bufferStatus = i;
            } 
            userLockInfos[msg.sender][bufferStatus] = userLockInfos[msg.sender][userLockInfos[msg.sender].length - 1];
            userLockInfos[msg.sender].pop();
            IERC721(smallNft).safeTransferFrom(address(this),msg.sender,_tokenId);
            totalPower = totalPower.sub(nftPower[smallNft]);
            userPower[msg.sender] = userPower[msg.sender].sub(nftPower[smallNft]);
            userSmallNftAmount[msg.sender] = userSmallNftAmount[msg.sender].sub(1);
            SmallNftAmount=SmallNftAmount.sub(1);
            emit unLockRecord(msg.sender, "SMALL_NODE_NFT",_tokenId, nftPower[smallNft]);
        }else if(_nftClass == 2) {
     require(IERC721(bigNft).balanceOf(address(this)) != 0 ," do not have a big node NFT");
            for(uint256 i =0 ; i< userLockInfos[msg.sender].length; i++){
                require(
               
                bigNft == userLockInfos[msg.sender][i].nft &&
                _tokenId == userLockInfos[msg.sender][i].tokenId,
                "You don t have this Big Node NFT");
                bufferStatus = i;

            }
            deleteNft(msg.sender,bufferStatus );
            IERC721(bigNft).safeTransferFrom(address(this),msg.sender,_tokenId);
            totalPower = totalPower.sub(nftPower[bigNft]);
            userPower[msg.sender] = userPower[msg.sender].sub(nftPower[bigNft]);
            userBigNftAmount[msg.sender] = userBigNftAmount[msg.sender].sub(1);
            BigNftAmount = BigNftAmount.sub(1);
            emit unLockRecord(msg.sender, "BIG_NODE_NFT",_tokenId, nftPower[bigNft]);

        }else if(_nftClass == 3){ 
     require(IERC721(supNft).balanceOf(address(this)) != 0 ," do not have a sup node NFT");
            for(uint256 i =0 ; i< userLockInfos[msg.sender].length; i++){
                require(
                supNft == userLockInfos[msg.sender][i].nft &&
                _tokenId == userLockInfos[msg.sender][i].tokenId ,
                "You don t have this Sup Node NFT");
                bufferStatus = i;
            }
            deleteNft(msg.sender,bufferStatus );
            IERC721(supNft).safeTransferFrom(address(this),msg.sender,_tokenId);
            totalPower = totalPower.sub(nftPower[supNft]);
            userPower[msg.sender] = userPower[msg.sender].sub(nftPower[supNft]);
            userSupNftAmount[msg.sender] = userSupNftAmount[msg.sender].sub(1);
            SupNftAmount = SupNftAmount.sub(1);
            emit unLockRecord(msg.sender, "SUP_NODE_NFT",_tokenId, nftPower[supNft]);

        }
    }
    function safeSrtTransfer(address _to, uint256 _amount) internal {
        uint256 srtBal = IERC20(srt).balanceOf(address(this));
          if (_amount > srtBal) {
            TransferHelper.safeTransfer(srt, _to, srtBal);
        } else {
            TransferHelper.safeTransfer(srt,_to,_amount);
        }
    }
    function getContractSrtBalance() public view returns(uint256) {
        return IERC20(srt).balanceOf(address(this));
    }
}