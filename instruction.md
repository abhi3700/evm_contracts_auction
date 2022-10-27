# Instruction

You should write a smart contract considering following technical and functional expectations. The smart contract outline is given but it is just to provide guidelines, the candidate is free to change the outline and overall structure of the final Contract/Project.

## Functional Expectation

- The contract should allow to carry out of multiple auctions
- Each Auction should accept multiple bids
- There is no price set by the Auction Owner, bidders can bid the price of their own. Every bidder can bid only once for the given Auction
- It is advised to have two different contracts
- Auction Repository – to store top-level Auction Contracts
- Actual Auction Contract – which holds the data for bids
- Auction contract should have a time limit to accept the bids
- Once the mentioned time limit is passed Auction should declare the highest bidder and close the auction for bids
- I would recommend using ERC20 standard to write both of these contracts
- We can extend the discussion for ERC721 once the candidate is ready with the contracts

## Technical Expectations

Should complete the implementation for the attached contract

Complete the assignment using the latest Smart Contract development methodologies

Should be deployable and testable

Should write tests

Should include README and documentation for Contract, development setup, and tests


Smart Contract Outline

AuctionRepository // owned by cros account

```solidity
mapping(address => address[]) live_auctions;
mapping(address => address[]) auction_history;
function createAuction(address asset, uint256 creationTime, uint256 startsAt, uint256 endsAt) public returns (address auction);
function getAllAuctions() public return (mapping(address => address[]) auctions); //should rerun all the auctions active + completed
function fetchAuction(address auctionContract) public return (mapping(address => address[]) auctions); // should return details of an auction
```

Auction // owned by Auction creator account
- mapping(address => uint256) public currentbids;
- address public highestBidder;
- address public owner;
- function auctionCreation(address asset, uint256 creationTime, uint256 startsAt, uint256 endsAt) public returns (address auction);
- function placeBid payable allowAfterStart notAfterEnd (address bidder, uint256 value) public returns (bool success);
- modifier allowAfterStart;
- modifier notAfterEnd;
- modifier onlyOwner;
- modifier notOnlyOwner;
- function withdraw(address sender) public returns (bool success);