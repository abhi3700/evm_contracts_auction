yarn run v1.22.19
$ hardhat flatten ./contracts/Auction.sol
// Sources flattened with hardhat v2.12.1 https://hardhat.org

// File contracts/interfaces/IGenericERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the GenericERC20 contract.
 */
interface IGenericERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function approveOwnership(address newOwner) external returns (bool);
    function transferFromOwnership(address newOwner) external returns (bool);
    function approvedOwnershipTo() external view returns (address);
}


// File contracts/dependencies/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/Context.sol@v4.7.3

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.7.3

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File @openzeppelin/contracts/security/Pausable.sol@v4.7.3

// SPDX-License-Identifier: MIT
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


// File contracts/Auction.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;




/// @title Auction Contract
/// @author @abhi3700
/// @notice Auction contract is kept separate & managed by AuctionRepository
/// @dev Auction contract which contains all data & related functions
contract Auction is Ownable, Pausable, ReentrancyGuard {
    // ==========State variables====================================
    mapping(address => uint256) public currentbids;
    address public asset;
    uint256 public creationTime;
    uint256 public startsAt;
    uint256 public endsAt;
    uint256 public highestBid;
    address public highestBidder;
    address public auctionRepository;
    address public originalAssetOwner;

    // ==========Events====================================
    event AuctionCreated(address indexed asset, uint256 creationTime, uint256 startsAt, uint256 endsAt);
    event Bid(address indexed bidder, uint256 amount);
    event BidWithdrawn(address indexed bidder, uint256 amount);
    event BidClaimed(address indexed bidder);
    event AssetReclaimed(address indexed originalAssetOwner);

    // ==========Modifiers====================================
    modifier allowAfterStart() {
        require(block.timestamp > startsAt, "Auction not started");
        _;
    }

    modifier notAfterEnd() {
        require(block.timestamp < endsAt, "Auction ended");
        _;
    }

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Only owner");
    //     _;
    // }

    // ==========Constructor====================================

    constructor() {
        auctionRepository = msg.sender;
    }
    // ==========Functions====================================
    /// @notice should return the auction contract address

    function initialize(address _owner, address _originalAssetOwner, address _asset, uint256 _startsAt, uint256 _endsAt)
        external
        whenNotPaused
        returns (bool)
    {
        require(msg.sender == auctionRepository, "only auctionRepository");

        // input validation is done only at factory level inside AuctionRepository
        creationTime = block.timestamp;
        transferOwnership(_owner);
        asset = _asset;
        startsAt = _startsAt;
        endsAt = _endsAt;
        originalAssetOwner = _originalAssetOwner;

        emit AuctionCreated(_asset, creationTime, startsAt, endsAt);

        return true;
    }

    /// @notice place bid more than the highest bid amount in chain token like ETH
    /// @dev bidder can place bid only once.
    function placeBid() public payable whenNotPaused allowAfterStart notAfterEnd returns (bool) {
        require(msg.value > highestBid, "Bid < highest bid");
        require(currentbids[msg.sender] == 0, "can bid only once");

        _setBid(msg.sender, msg.value);

        emit Bid(msg.sender, msg.value);
        return true;
    }

    /// @notice private function for setting bid
    /// @param _bidder the bidder
    /// @param _bidamt the bid amount
    function _setBid(address _bidder, uint256 _bidamt) private {
        currentbids[_bidder] = _bidamt;
        highestBid = _bidamt;
        highestBidder = _bidder;
    }

    /// @notice should withdraw the previous highest bids only after the auction ends.
    /// @dev can withdraw only after the auction ends so that the bid can be only once per bidder.
    function withdrawBid() external whenNotPaused nonReentrant returns (bool) {
        uint256 amount = currentbids[msg.sender];
        // NOTE: Here, withdrawal of bid amount is possible irrespective of the auction status (started or ended).
        // require(amount != highestBid, "highest bidder cannot withdraw");

        // NOTE: Here, withdrawal of bid amount is possible only after the auction ends, otherwise, the bidder
        // can withdraw the bid amount & then re-bid.
        require(block.timestamp > endsAt, "Auction not ended");
        currentbids[msg.sender] = 0;

        if (amount == highestBid) {
            revert("Highest bidder cannot withdraw");
        }

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed.");

        emit BidWithdrawn(msg.sender, amount);

        return true;
    }

    /// @notice claim bid as highest bidder only after the auction ends.
    /// @return status true if successful
    function claimPossession() external whenNotPaused nonReentrant returns (bool) {
        require(block.timestamp > endsAt, "Auction not ended");
        require(msg.sender == highestBidder, "Only highest bidder can claim");
        uint256 _currentBid = currentbids[msg.sender];

        require(_currentBid > 0, "Bid already claimed");

        currentbids[msg.sender] = 0;

        // transfer the ownership of the token from Auction SC to highest bidder
        IGenericERC20(asset).transferOwnership(msg.sender);

        // transfer the highest bid amount to the original asset owner
        (bool success,) = originalAssetOwner.call{value: highestBid}("");
        require(success, "Transfer failed.");

        emit BidClaimed(msg.sender);

        return true;
    }

    /// @notice reclaim the asset back to the original asset owner only after the auction ends.
    /// @dev only when there is no bid placed.
    function reclaimAsset() external whenNotPaused nonReentrant returns (bool) {
        require(block.timestamp > endsAt, "Auction not ended");
        require(msg.sender == originalAssetOwner, "Only original asset owner can reclaim");
        require(highestBid == 0, "Bid placed, cannot reclaim");

        // transfer the ownership of the asset from 'Auction SC' to 'original asset owner'
        IGenericERC20(asset).transferOwnership(msg.sender);

        emit AssetReclaimed(msg.sender);

        return true;
    }

    // ------------------------------------------------------------------------------------------
    /// @notice Pause contract
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
}
Done in 0.84s.
