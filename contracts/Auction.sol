// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IGenericERC20.sol";
import "./dependencies/ReentrancyGuard.sol";

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
    function claimBid() external whenNotPaused nonReentrant returns (bool) {
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
