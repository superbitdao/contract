
//SPDX-License-Identifier: UNLICENSED

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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
interface INft{
       function burnNFT(address _user,uint256 _tokenId) external;
}
interface IV3NFT{
      function mint(address _to) external ;
}
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract NFTLockV is Ownable,ReentrancyGuard,Pausable{ 
    using SafeMath for uint256;
    struct lockInfo{
        uint256 tokenId;
        address user;
        address nft;
        uint256 startAmount;
        uint256 amount;
        uint256 startTime;
        uint256 time;
        uint256 startTimeBlock;
        uint256 endLockTime;
        uint256 lockBlockNumbers;
    }
    uint256 orderId;
    uint256 public lockBlockNumber;
    uint256 public reward;
    uint256 public rewardTime;
    uint256 public startRewardTime;
    address public supNode;
    address public bigNode;
    address public smallNode;
    address public srt;
    uint public intervalTime = 3;
    
    uint public day = 86400;
    uint256 public userTotalClaim;
    uint256 public smallNodeAmount;
    uint256 public bigNodeAmount;
    uint256 public supNodeAmount;
    mapping(address => uint256 ) public nftToReward;
    mapping (address => lockInfo[]) public lockInfos;
    mapping(address => address) public mintNew;
    event claimSrtRecord(address user,uint256 amount);
    event lockRecord(uint256 id,address user, address nft, uint256 tokenId, uint256 amount);
    event adminDeposit(address admin,address token,uint256 amount);
    event adminWithdraw(address admin,address token,uint256 amount);
 constructor(address _supNode, address _bigNode, address _smallNode,address _supNode1, address _bigNode1, address _smallnode1,address _srt){
        srt = _srt;
        supNode = _supNode;
        bigNode = _bigNode;
        smallNode = _smallNode;
        setLockTime(1000);
        mintNew[_supNode] =_supNode1 ;
        mintNew[_bigNode] =_bigNode1 ;
        mintNew[_smallNode] = _smallnode1;
 }
 function deposit(uint256 _amount) public onlyOwner{
    TransferHelper.safeTransferFrom(srt, msg.sender, address(this), _amount);
    emit adminDeposit(msg.sender, srt, _amount);
 }
 function backToken(uint256 _amount) public onlyOwner{
    TransferHelper.safeTransfer(srt,msg.sender,_amount);
    emit adminWithdraw(msg.sender, srt,_amount);
 }
 function setSrt(address _srt) public onlyOwner{
    srt =_srt;
 }
 function setSupNode(address _supNode) public onlyOwner{
        supNode = _supNode;
 }
 function setBigNode(address _bigNode) public onlyOwner{
        bigNode = _bigNode;
 }
 function setSmallNode(address _smallNode) public onlyOwner{
        smallNode = _smallNode;
 }
 function setLockTime(uint256 _day) public onlyOwner{
    lockBlockNumber = _day.mul(day).div(intervalTime);
 }
 function setNftToReward(address _nft, uint256 _amount) public onlyOwner{
    nftToReward[_nft] = _amount;
 }
 function mintToNew(address addr1,address addr2) public onlyOwner{
    mintNew[addr1] = addr2;
 }
function staking(address _nft,uint256 _id) public whenNotPaused {
    require(nftToReward[_nft] != 0 , "plz input current nft address");
    require(IERC721(_nft).balanceOf(msg.sender) >0);
    require(IERC721(_nft).ownerOf(_id) == msg.sender);
    if(_nft == smallNode){
        smallNodeAmount++;
    }else if(_nft == bigNode){
        bigNodeAmount++;
    }else if(_nft == supNode){
        supNodeAmount++;
    }else{
        
    }
    INft(_nft).burnNFT(msg.sender,_id);
    IV3NFT(mintNew[_nft]).mint(msg.sender);
    lockInfo memory info = lockInfo({
        tokenId:_id,
        user:msg.sender,
        nft:_nft,
        startAmount:nftToReward[_nft],
        amount:nftToReward[_nft],
        startTime:block.timestamp,
        time:block.number,
        startTimeBlock:block.number,
        endLockTime: block.number.add(lockBlockNumber),
        lockBlockNumbers: lockBlockNumber
    });
    lockInfos[msg.sender].push(info);

    emit lockRecord(orderId, msg.sender,_nft,_id,nftToReward[_nft]);
    orderId ++;
}
function userTotalLock(address _user) public view returns(uint256) {
    uint256 total = 0;
    for(uint256 i = 0; i< lockInfos[_user].length;i++){
        total = total+ lockInfos[_user][i].amount;
    }
    return total;
}
function CanClaimSrt(address _user) public view returns(uint256){
    uint256 total = 0;
    for(uint256 i = 0; i< lockInfos[_user].length;i++){
        if(block.number - lockInfos[_user][i].time > 0){
            uint256 OneBlockReward = lockInfos[_user][i].startAmount/lockInfos[_user][i].lockBlockNumbers;
            uint256 _time = block.number - lockInfos[_user][i].time; 
            total= total+ OneBlockReward*_time;
        }
    }
    return total;
}
function Claim(address _user) public whenNotPaused{
    uint256 total = 0;
    for(uint256 i =0; i< lockInfos[_user].length;i++){
        if(block.number - lockInfos[_user][i].time > 0){
            uint256 OneBlockReward = lockInfos[_user][i].startAmount/lockInfos[_user][i].lockBlockNumbers;
            uint256 _time = block.number - lockInfos[_user][i].time; 
            uint256 _reward = OneBlockReward*_time;
            total= total+ _reward;
            lockInfos[_user][i].time = block.number;
            lockInfos[_user][i].amount = lockInfos[_user][i].amount - _reward;

        }
    }
    userTotalClaim = userTotalClaim.add(total);
    TransferHelper.safeTransfer(srt,_user,total);
    emit claimSrtRecord(msg.sender, total);
} 
function getUserLockLength(address _user) public view returns(uint256){
    return lockInfos[_user].length;
}
      /**
     * @dev Pause staking.
     */
    function pause() external onlyOwner {
        _pause();
    }
    /**
     * @dev Resume staking.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}