pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title TokenVesting
 * @dev This contract handles the vesting of a ERC20 tokens for a 10 beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 */
contract TokenVesting {
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    uint64 private prev ;
    uint256 private Total_beneficiary;
    mapping(address => uint256) private _erc20Released;
    address[] public _beneficiary;
    uint64 private _start;
    uint64 private immutable _duration;
    uint256 private vesting_time;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address[] memory beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint256 _total_beneficiary,
        uint256 _vesting_time
    ) {
        Total_beneficiary = _total_beneficiary;
        for(uint i = 0 ; i< Total_beneficiary ;i++){
            require(beneficiaryAddress[i] != address(0), "VestingWallet: beneficiary is zero address");
        }
        for(uint i = 0 ; i< Total_beneficiary ;i++){
            _beneficiary.push(beneficiaryAddress[i]);
        }
        _start = startTimestamp;
        _duration = durationSeconds;
        vesting_time = _vesting_time;
        prev = _start;
    }

    /**
     @dev Release the tokens that have already vested.
     *
     Emits a {TokensReleased} event.
     */
    function release(address token) public virtual {
        uint256 releasable = vestedAmount(token, uint64(block.timestamp)) ;
        _erc20Released[token] += (releasable*Total_beneficiary);
        emit ERC20Released(token, _erc20Released[token]);
        for(uint i = 0 ; i< Total_beneficiary ;i++){
            SafeERC20.safeTransfer(IERC20(token),_beneficiary[i], releasable);
        }
        
    }

    /**
     Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint64 timestamp) public  virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this))/Total_beneficiary + (released(token)/Total_beneficiary), timestamp);
    }

    /**
     Virtual implementation of the vesting formula. This returns the amount vested
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal virtual returns (uint256) {
        
        if (timestamp > start() + duration()) {
            return totalAllocation;
        } 
        else if (timestamp > start() && timestamp - prev >= vesting_time) {
            prev = timestamp; 
            return (totalAllocation *vesting_time) / duration();
        }
        else {
            return 0;
        }
    }
    
    /**
      Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    function getNow() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }
    
    /**
     Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    /**
     Amount of token of beneficiary
     */
    function beneficiary_bal(address token,uint index) public view virtual returns (uint256) {
        return IERC20(token).balanceOf(_beneficiary[index]);
    }

    /**
     Amount of token locked in this smart contract
     */
    function token_locked(address token,uint index) public view virtual returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
    
    
}


