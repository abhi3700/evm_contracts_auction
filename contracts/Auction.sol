// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./dependencies/CheckContract.sol";

contract Auction is Pausable, CheckContract {
    // ==========State variables====================================
    mapping(address => uint256) public currentbids;
    address public owner;
    address public asset;
    uint256 public creationTime;
    uint256 public startsAt;
    uint256 public endsAt;
    uint256 public highestBid;
    address public highestBidder;

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
    // ==========Functions====================================
    /// @notice should return the auction contract address
    function auctionCreation(address _asset, uint256 _startsAt, uint256 _endsAt) public returns (bool) {
        checkContract(_asset);
        require(_startsAt > block.timestamp, "startsAt > creationTime");
        require(_endsAt > _startsAt, "endsAt < startsAt");

        creationTime = block.timestamp;
        owner = msg.sender;
        asset = _asset;
        startsAt = _startsAt;
        endsAt = _endsAt;

        // TODO: check if any id or status is required when auction is created.
        emit AuctionCreated(_asset, creationTime, startsAt, endsAt);

        return true;
    }

    /// @notice place bid more than the highest bid amount in chain token like ETH
    /// @dev bidder can place bid only once.
    function placeBid() public payable allowAfterStart notAfterEnd returns (bool) {
        require(msg.value > highestBid, "Bid < highest bid");
        require(block.timestamp > startsAt, "< startsAt");
        require(block.timestamp < endsAt, "> endsAt");
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

    /// @notice should withdraw the highest bid
    /// @dev can withdraw only after auction ends
    function withdraw() external returns (bool) {
        uint256 amount = currentbids[msg.sender];
        // NOTE: Here, withdrawal of bid amount is possible irrespecitve of the auction status (started or ended).
        require(amount != highestBid, "highest bidder cannot withdraw");
        currentbids[msg.sender] = 0;

        if (amount == highestBid) {
            revert("Highest bidder cannot withdraw");
        }

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed.");

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
