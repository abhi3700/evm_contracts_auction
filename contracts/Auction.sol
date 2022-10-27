// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./dependencies/ReentrancyGuard.sol";
import "./dependencies/CheckContract.sol";

contract Auction is Pausable, CheckContract, ReentrancyGuard {
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

    // ERC721 asset related params
    // IERC721 public collection;
    // uint256 public tokenId;
    // address public currentOwner;

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

    function initialize(address _asset, uint256 _startsAt, uint256 _endsAt) external returns (bool) {
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

    /// @notice place bid more than the highest bid amount (so far) in chain tokens like ETH, MATIC, BNB, etc.
    /// @dev bidder can place bid only once & the previous highest bidder is refunded
    function placeBid() external payable allowAfterStart notAfterEnd returns (bool) {
        require(block.timestamp > startsAt, "< startsAt");
        require(block.timestamp < endsAt, "> endsAt");
        uint256 previousBid = highestBid;
        require(msg.value > previousBid, "Bid < highest bid");
        require(currentbids[msg.sender] == 0, "can bid only once");

        address previousBidder = highestBidder;

        // for 2nd time onwards
        if (previousBidder != address(0)) {
            // refund to the previous highest bidder
            (bool success,) = payable(previousBidder).call{value: previousBid}("");
            require(success, "Withdrawal failed.");
        }

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

    /// @notice should withdraw the asset (ERC20) to the highest bidder after the auction ends
    /// NOTE: The asset standard can be extended to ERC721 as well
    /// @dev can withdraw only after auction ends
    function claimBid() external nonReentrant returns (bool) {
        require(block.timestamp > endsAt, "Auction not ended");

        address _highestBidder = highestBidder;
        uint256 _tokenId = tokenId;

        // TODO: Make it to work with ERC721, as token ID has to be transferred to the highest bidder (winner eventually)
        collection.safeTransferFrom(address(this), _highestBidder, _tokenId);
        emit BidClaimed(currentOwner, _tokenId, _highestBidder);

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
