// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC20 {
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function transfer(address dst, uint256 amount) external returns (bool success);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    function approve(address spender, uint256 amount) external returns (bool success);

    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);
}


interface TenFiFarm {

    function poolInfo(uint256 pid) external view returns(address want,uint256 allocPoint ,uint256 lastRewardBlock ,uint256 accTENFIPerShare ,address strat);

    function stakedWantTokens(uint256 pid,address user) external view returns(uint256);
}


interface BiswapFarm {

    function poolInfo(uint256 pid) external view returns(address lpToken,uint256 allocPoint,uint256 lastRewardBlock,uint256 accBSWPerShare);

    function userInfo(uint256 pid,address user) external view returns(uint256 amount,uint256 rewardDebt);
}


interface BeefyFarm {

    function balanceOf(address user) external view returns(uint256);

    function balance() external view returns(uint256);

    function totalSupply() external view returns(uint256);

    function want() external view returns(address);

}


interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract Airdrop is Ownable,ReentrancyGuard {

    
   /**
    * @notice 
    * NOT_ENTERD = USER HAS NOT REGISTERED FOR AIRDROP
    * INSIDE = USER IS PRESENT IN AIRDROP
    * FINISHED = USER GET ALL 4 ROUND REWARDS IN 360 DAYS DURATION
    * EXPELLED = USER'S TENFI BALANCE IS LESS THAN THE TENFI HE HAS AT TIME OF AIRDROP REGISTRATION 
    */
    enum Status {
        NOT_ENTERED,
        INSIDE,
        FINISHED,
        EXPELLED
    }


   /**
    * @notice Container for user round data information
    * @member isClaim = user has got airdrop rewards for this round or not
    * @member claimAmount = how much airdrop rewards for this round user got
    */
    struct UserRoundData {
        bool isClaim;
        uint256 claimAmount;
    }

   /**
    * @notice addressof tenfi token
    */
    address public constant TENFI_ADDRESS = 0xd15C444F1199Ae72795eba15E8C1db44E47abF62;

   /**
    * @notice address which has right to transfer and register the register for airdrop
    */
    address public transferrer;


   /**
    * @notice address of farms
    */
    address public constant TENFI_FARM  = 0x264A1b3F6db28De4D3dD4eD23Ab31A468B0C1A96;
    address public constant BISWAP_FARM = 0xDbc1A13490deeF9c3C12b44FE77b503c1B061739;
    address[] public beefyFarms = [0x0Ce6FeC7521b7d054b5B0a5F43D49120f9d6CFbc,0x00F204F524a433f45a6278c2C0E10F5292b3C5B9];

   /**
    * @notice EIP20Interface type of lend token Address
    */
    IERC20 public _lendAddress;

   /**
    * @notice multiplier for getting airdrop rewards for his tenfi amount at registration time   
    */
    uint256 public constant AIRDROP_REWARDS_INCREASE_FACTOR = 2e18;

   /**
    * @notice this is rewards duration for each round in 360 days   
    */
    uint256 public constant REWARDS_DURATION = 270;        // change to 90 days in production

   /**
    * @notice this is min qualify amount to register in airdrop   
    */
    uint256 public constant MIN_QUALIFY_AMOUNT = 1e18;  // change to 10000e18 in production

   /**
    * @notice timstamp at which airdrop will start for all registered users
    */
    uint256 public airdropStartTime;

   /**
    * @notice total LEND alloted to users who have registered succesfully before first airdrop
    */
    uint256 public totalLendAllotedToUsers;

   /**
    * @notice total amount of LEND airdrpped till now
    */
    uint256 public totalLendAirdropped;

   /**
    * @notice mapping to check whether user is eligible for airdrop 
    */
    mapping (address => Status) public isUserInAirdrop;

   /**
    * @notice mapping to check whether user is eligible for airdrop 
    */
    mapping (address => uint256) public userLastClaimRound;

   /**
    * @notice mapping to get user's claimed balance in each 90 days interval
    */
    mapping (address => mapping(uint256 => UserRoundData)) public userClaimDetails;

   /**
    * @notice update this mapping once user has successfully registered for airdrop
    */
    mapping (address => uint256) public tenfiAtWhichUserIsRegistered;
    
   /**
    * @notice update this mapping once user has successfully registered for airdrop
    */
    mapping (address => uint256) public totalLendAlloted;

   /**
    * @notice update this mapping once user has successfully registered for airdrop
    * its value will be totalLendAlloted to this address divide by 4
    */
    mapping (address => uint256) public lendToGivenEvery90Days;
    
   /**
    * @notice store user addresses who registered for airdrop
    */
    address[] public registeredUsers;

   /**
    * @notice store user addresses who are expelled
    */
    address[] public expelledUsers;

   /**
    * @notice store vault poolId's to count user balance in it
    */
    uint[] public registeredTenfiFarmVaultsId = [14,15,16,61];

   /**
    * @notice store vault poolId's to count user balance in it
    */
    uint[] public registeredBiswapFarmVaultsId = [59];

   /**
    * @notice store index of user address in registeredUsers array
    */
    mapping(address => uint256) public userIndexInRegistered;
    
    
    event TransferrerSet(address oldTransferrer, address newTransferrer);

    event TransferrerRemoved(address oldTransferrer);
    
    event lendTransfered(address user,uint256 round,uint256 amount);

    event lendWithdrawn(uint256);

    constructor (IERC20 lendAddress) {
        _lendAddress = lendAddress;
        airdropStartTime = block.timestamp + (60 * 60 * 4) ;
        registeredUsers.push(address(0));
    }

    modifier OnlyTransferrer() {
        require(msg.sender == transferrer, "only transferrer can call");
        _;
    }

    function changeTime(uint new_time) external onlyOwner{
        airdropStartTime = new_time;
    }

   /**
    * @notice Owner can withdraw the lend tokens at any time
    * @param amount The amount of the LEND tokens owner wants to withdraw 
    * @return success (bool) boolean value whether transaction is successful or not.
    */
    function withdrawLend(uint256 amount) external onlyOwner returns(bool success){
        success = _lendAddress.transfer(owner(), amount); 
        require(success,"withdraw failed"); 
        emit lendWithdrawn(amount);
    }


   /**
    * @notice User can register for airdrop 
    *
    *
    * Requirements:
    *
    * - current time should be less than starting time of airdrop.
    * - at time of registration user's tenfi balance should greater
    *   than or equal to minimum qualifying amount.
    * - user cannot register again for the airdrop.
    */
    function register() external nonReentrant {

        require(block.timestamp < airdropStartTime,"Registration time already ended");

        address user = _msgSender();

        uint256 tenfi_amount = getUserTenfiBalance(user);

        require(tenfi_amount >= MIN_QUALIFY_AMOUNT,"Insufficient tenfi balance to qualify");
       
        require(isUserInAirdrop[user] == Status.NOT_ENTERED,"Given user not allowed , he has already registered one time");
        
        isUserInAirdrop[user] = Status.INSIDE;

        uint256 alloted = (tenfi_amount * AIRDROP_REWARDS_INCREASE_FACTOR) / 1e18;
        
        totalLendAlloted[user] = alloted;
        totalLendAllotedToUsers += alloted;
        lendToGivenEvery90Days[user] = alloted / 4;

        tenfiAtWhichUserIsRegistered[user] = tenfi_amount;

        registeredUsers.push(user);

        userIndexInRegistered[user] = registeredUsers.length - 1;

    }

   /**
    * @notice Transferrer can Expell a user from airdrop
    * @param user address of user transferrer want to expell
    *
    * Requirements:
    *
    * - Given user should present in the airdrop at time of expelling.
    */
    function changeStatusToExpelled(address user) external OnlyTransferrer {

        require(isUserInAirdrop[user] == Status.INSIDE,"User Already Finished or Expelled or Not Entered");

        isUserInAirdrop[user] = Status.EXPELLED;

        address user_on_last_index = registeredUsers[registeredUsers.length - 1];

        if(user_on_last_index != user){
            uint256 index_of_user = userIndexInRegistered[user];
            registeredUsers[index_of_user] = user_on_last_index;
            userIndexInRegistered[user_on_last_index] = index_of_user;
        }
            
        registeredUsers.pop();
        expelledUsers.push(user);
        delete userIndexInRegistered[user];
        return;
    }

   /**
    * @notice Transfer user his pending airdrop rewards
    *
    *
    * Requirements:
    *
    * - User current tenfi balance should be greater than the tenfi 
    *   balance at the time of registration.
    * - User does not come early for airdrop. 
    */
    function transferLEND() external nonReentrant {

       /*
        *if user status is INSIDE it means that the user is 
        * getting airdrop for 1st round
        * getting airdrop for other rounds except 1st means previous rounds are successfull
        */

        address user = _msgSender();

        bool flag = canWeTransferLend(user);// check user has sufficient tenfi balance
        
        require(flag == true,"User not have sufficient tenfi or not inside the airdrop");

        uint256 amount = lendToGivenEvery90Days[user];

        uint256 last_round = userLastClaimRound[user];

        uint256 current_round = last_round + 1;

        uint256 calculated_timestamp = airdropStartTime + (current_round * REWARDS_DURATION);

        require(calculated_timestamp < block.timestamp ,"!!Too Early");

        uint amountToBeTransferred;

        while(calculated_timestamp < block.timestamp){

            UserRoundData storage round_details = userClaimDetails[user][current_round];

            round_details.isClaim = true;
            round_details.claimAmount = amount;

            if(current_round == 4) {
                
                isUserInAirdrop[user] = Status.FINISHED;

                address user_on_last_index = registeredUsers[registeredUsers.length - 1];

                if(user_on_last_index != user){
                    uint256 index_of_user = userIndexInRegistered[user];
                    registeredUsers[index_of_user] = user_on_last_index;
                    userIndexInRegistered[user_on_last_index] = index_of_user;
                }
            
                registeredUsers.pop();
                delete userIndexInRegistered[user];
            }

            userLastClaimRound[user] = current_round;

            amountToBeTransferred += amount;

            totalLendAirdropped += amount;
        
            emit lendTransfered(user,current_round,amount);

            if(current_round != 4) {
                current_round = current_round + 1;
                calculated_timestamp = airdropStartTime + (current_round * REWARDS_DURATION);
            }
            else {
                break;
            }

        }

        _lendAddress.transfer(user, amountToBeTransferred);

    }
    
   /**
    * @notice It will the transferrer address
    *
    *
    * Requirements:
    *
    * - only owner can call this function. 
    */
    function setTransferrer(address _transferrer) external onlyOwner {
        address oldTransferrer = transferrer;
        transferrer = _transferrer;
        emit TransferrerSet(oldTransferrer, _transferrer);
    }
    
   /**
    * @notice It will remove the transferrer address
    *
    *
    * Requirements:
    *
    * - only owner can call this function. 
    */
    function removeTransferrer() external onlyOwner {
        address oldTransferrer = transferrer;
        transferrer = address(0);
        emit TransferrerRemoved(oldTransferrer);
    }

   /**
    * @notice Get pending LEND token balance of given user
    * @dev This is used by frontend to display pending LEND user has to claim.
    * @param user Address of the account to get pending LEND
    * @return (uint256) pending lend balance
    */
    function getPendingLendOfUser(address user) external view returns(uint256) {
        
        if(isUserInAirdrop[user] == Status.INSIDE){
            
            uint256 amount;

            uint256 last_round = userLastClaimRound[user];

            uint256 current_round = last_round + 1;

            uint256 calculated_timestamp = airdropStartTime + (current_round * REWARDS_DURATION);

            uint256 flag = 0;

            while(calculated_timestamp < block.timestamp) {

                flag = flag + 1;
                current_round = current_round + 1;

                if(current_round == 5)
                break;

                calculated_timestamp = airdropStartTime + (current_round * REWARDS_DURATION);

            }

            amount = flag * lendToGivenEvery90Days[user];
            return amount;

        }
        return 0;
    }

   /**
    * @notice number of users who are still in airdrop process.
    * @dev This is used by backend to tracking and expelling process.
    * @return (uint256) number of users who are still in airdrop process.
    */    
    function getRegisteredUsersLength() external view  returns(uint256) {
        return registeredUsers.length - 1;
    }

   /**
    * @notice Get array of those users who are still in airdrop process.
    * @dev This is used by backend to tracking and expelling process.
    * @return (uint256[]) users who are still in airdrop process.
    */     
    function getRegisteredUsers() external view returns(address[] memory) {
        
        address[] memory arr = new address[](registeredUsers.length - 1);
        for(uint256 i = 1 ; i < registeredUsers.length ; i++) {
            address user = registeredUsers[i];
            arr[i-1] = user;
        }
        return arr;
    }

   /**
    * @notice number of users who are expelled in airdrop process.
    * @dev This is used by frontend to show how many users are expelled.
    * @return (uint256) number of users who are expelled in airdrop process.
    */ 
    function getExpelledUsersLength() external view returns(uint256) {
        return expelledUsers.length;
    }

   /**
    * @notice Get array of those users who are expelled in airdrop process.
    * @dev This is used by frontend to show users who are expelled.
    * @return (uint256[]) users who are expelled in airdrop process.
    */  
    function getExpelledUsers() external view returns(address[] memory) {
        
        address[] memory arr = new address[](expelledUsers.length);
        for(uint256 i = 0 ; i < expelledUsers.length ; i++) {
            address user = expelledUsers[i];
            arr[i] = user;
        }
        return arr;
    }

   /**
    * @notice Get amount of TENFI token present in given amount of LP
    *         in given LP token address.
    * @param lp Address of the LP token in which we have to check tenfi bal.
    * @param amount amount of the LP token for which we have to check tenfi bal.
    * @return result (uint256) amount of TENFI.
    */ 
    function getTenfiInThisLp(address lp,uint256 amount) public view returns(uint result) {
        
        uint256 totalSupply = IPancakePair(lp).totalSupply();


        address token0 = IPancakePair(lp).token0();

        uint112 reserves;
        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(lp).getReserves();
        
        if(token0 == TENFI_ADDRESS)
        reserves = reserve0;
        else
        reserves = reserve1;

        result = (amount * reserves) / totalSupply;
    }

   /**
    * @notice return user tenfi balance he have in wallet or in farm vaults.
    * @param user Address of the user for which we have to check tenfi balance.
    * @return tenfi_bal (uint256) amount of TENFI.
    */ 
    function getUserTenfiBalance(address user) public view returns(uint tenfi_bal) {
        

        address _tenfiAddress = TENFI_ADDRESS; //gas-savings
        //User wallet tenfi balance
        tenfi_bal += IERC20(_tenfiAddress).balanceOf(user);

        uint256 tenfi_farm_length = registeredTenfiFarmVaultsId.length;

        //User Tenfi balance in tenfi pools
        for(uint256 i = 0 ; i < tenfi_farm_length ; i++) {
            uint256 id = registeredTenfiFarmVaultsId[i];
            uint256 staked = TenFiFarm(TENFI_FARM).stakedWantTokens(id,user);
            if(staked != 0){
                (address pool_lp,,,,) = TenFiFarm(TENFI_FARM).poolInfo(id); 
                if(pool_lp != _tenfiAddress)
                tenfi_bal += getTenfiInThisLp(pool_lp,staked);
                else
                tenfi_bal += staked;
            }
        }

        uint256 biswap_farm_length = registeredBiswapFarmVaultsId.length;

        //User Tenfi balance in biswap pools
        for(uint256 i = 0 ; i < biswap_farm_length ; i++) {
            uint256 id = registeredBiswapFarmVaultsId[i];
            (uint256 staked,) = BiswapFarm(BISWAP_FARM).userInfo(id,user);
            if(staked != 0) {
                (address pool_lp,,,) = BiswapFarm(BISWAP_FARM).poolInfo(id);
                tenfi_bal += getTenfiInThisLp(pool_lp,staked);
            }

        }

         uint256 beefy_farms_length = beefyFarms.length;

        //User Tenfi balance in biswap pools
        for(uint256 i = 0 ; i < beefy_farms_length ; i++) {

            (uint256 _balanceOf) = BeefyFarm(beefyFarms[i]).balanceOf(user);
            (uint256 _balance) = BeefyFarm(beefyFarms[i]).balance();
            (uint256 _totalSupply) = BeefyFarm(beefyFarms[i]).totalSupply();
            uint256 staked = (_balanceOf * _balance) / _totalSupply;
            if(staked != 0) {
                (address pool_lp) = BeefyFarm(beefyFarms[i]).want();
                tenfi_bal += getTenfiInThisLp(pool_lp,staked);
            }
        }
        
    }

   /**
    * @notice return true or false whether we can transfer LEND to user.
    * @param user Address of the user for which we have to check.
    * @return flag (bool) true or false.
    */ 
    function canWeTransferLend(address user) public view returns(bool flag) {

        if(isUserInAirdrop[user] != Status.INSIDE) {
            
            flag = false;

        }
        else {

            uint256 tenfi_amount = getUserTenfiBalance(user);

            if(tenfi_amount < tenfiAtWhichUserIsRegistered[user]) {
                flag = false;
            }
            else {
                flag = true;
            }

        }
    }

}