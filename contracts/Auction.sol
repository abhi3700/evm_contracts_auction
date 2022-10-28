// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./dependencies/ReentrancyGuard.sol";

/// @title Auction Contract
/// @author @abhi3700
/// @notice Auction contract is kept separate & managed by AuctionRepository
/// @dev Auction contract which contains all data & related functions
contract Auction is Pausable, ReentrancyGuard {
    // ==========State variables====================================
    mapping(address => uint256) public currentbids;
    address public owner;
    address public asset;
    uint256 public creationTime;
    uint256 public startsAt;
    uint256 public endsAt;
    uint256 public highestBid;
    address public highestBidder;
    address public auctionRepository;

    // ==========Events====================================
    event AuctionCreated(address indexed asset, uint256 creationTime, uint256 startsAt, uint256 endsAt);
    event Bid(address bidder, uint256 amount);

    // ==========Modifiers====================================
    modifier allowAfterStart() {
        require(block.timestamp > startsAt, "Function called too early");
        _;
    }

    modifier notAfterEnd() {
        require(block.timestamp < endsAt, "Function called too late");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // ==========Constructor====================================
    constructor() {
        auctionRepository = msg.sender;
    }
    // ==========Functions====================================
    /// @notice should return the auction contract address

    function initialize(address _asset, uint256 _startsAt, uint256 _endsAt) external whenNotPaused returns (bool) {
        require(msg.sender == auctionRepository, "only auctionRepository");

        // input validation is done only at factory level inside AuctionRepository
        creationTime = block.timestamp;
        owner = msg.sender;
        asset = _asset;
        startsAt = _startsAt;
        endsAt = _endsAt;

        emit AuctionCreated(_asset, creationTime, startsAt, endsAt);

        return true;
    }

    /// @notice place bid more than the highest bid amount in chain token like ETH
    /// @dev bidder can place bid only once.
    function placeBid() public payable whenNotPaused allowAfterStart notAfterEnd returns (bool) {
        require(block.timestamp > startsAt, "< startsAt");
        require(block.timestamp < endsAt, "> endsAt");
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

    /// @notice should withdraw the previous highest bids
    /// @dev can withdraw irrespective of the auction status (started or ended).
    function withdraw() external whenNotPaused nonReentrant returns (bool) {
        uint256 amount = currentbids[msg.sender];
        // NOTE: Here, withdrawal of bid amount is possible irrespective of the auction status (started or ended).
        require(amount != highestBid, "highest bidder cannot withdraw");
        currentbids[msg.sender] = 0;

        if (amount == highestBid) {
            revert("Highest bidder cannot withdraw");
        }

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed.");

        return true;
    }

    // function claimBid() external whenNotPaused nonReentrant allowAfterStart notAfterEnd returns (bool) {
    //     require(msg.sender == highestBidder, "Only highest bidder can claim");
    //     require(currentbids[msg.sender] == highestBid, "Only highest bidder can claim");

    //     currentbids[msg.sender] = 0;
    //     transfer the ownership of the token from existing to new owner
    //     IERC20(asset).transfer(msg.sender, highestBid);

    //     return true;
    // }

    // function reclaimAsset()

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
