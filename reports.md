# Reports

## Coverage

```console
❯ yarn coverage
yarn run v1.22.19
warning ../../../../package.json: No license field
$ hardhat coverage --solcoverjs ./.solcover.js --temp build --network hardhat

Version
=======
> solidity-coverage: v0.7.22

Instrumenting for coverage...
=============================

> Auction.sol
> AuctionRepository.sol
> dependencies/CheckContract.sol
> dependencies/ReentrancyGuard.sol
> GenericERC20.sol
> interfaces/IAuction.sol
> interfaces/IAuctionRepository.sol
> interfaces/IGenericERC20.sol

Compilation:
============

Warning: Contract code size is 30732 bytes and exceeds 24576 bytes (a limit introduced in Spurious Dragon). This contract may not be deployable on mainnet. Consider enabling the optimizer (with a low "runs" value!), turning off revert strings, or using libraries.
  --> contracts/AuctionRepository.sol:19:1:
   |
19 | contract AuctionRepository is Ownable, Pausable, CheckContract, ReentrancyGuard {
   | ^ (Relevant source part starts here and spans across multiple lines).


Generating typings for: 14 artifacts in dir: ./build/typechain/ for target: ethers-v5
Successfully generated 46 typings!
Compiled 14 Solidity files successfully

Network Info
============
> HardhatEVM: v2.12.1
> network:    hardhat



  AuctionRepository contract
    Ownable
      ✔ Should return the correct owner
      ✔ Owner should be able to transfer ownership
      ✔ Non-owner should not be able to transfer ownership
    Pausable
      ✔ Owner should be able to pause when NOT paused
      ✔ Owner should be able to unpause when already paused
      ✔ Owner should not be able to pause when already paused
      ✔ Owner should not be able to unpause when already unpaused
    createAuction
      ✔ An asset owner should not be able to create auction when paused
      ✔ Only asset owner should be able to create an auction (85ms)
      ✔ asset owner should not be able to create multiple auctions for same asset (106ms)
      ✔ An owner holding multiple assets can create auction for respective asset (213ms)
      ✔ Individual owner(s) should be able to create auction for their respective assets (216ms)
      ✔ should fail when asset is not a contract address
      ✔ should fail when startsAt < now
      ✔ should fail when endsAt < startsAt
    updateLiveAuctions
      ✔ Only owner should be able to update live auctions (117ms)
      ✔ Non-owner should not be able to update live auctions
      ✔ Owner should not be able to update live auctions when paused
      ✔ should fail when asset is not a contract address
      ✔ should fail when no auction created
    getAllAuctions
      ✔ should return an empty array if no auctions exist
      ✔ should fail when asset is not a contract address
    getLiveAuctions
      ✔ should return an empty array if no auctions exist
      ✔ should fail when asset is not a contract address
    fetchAuction
      ✔ should return auction details
      ✔ should fail when auction is not a contract address

  Auction contract
    Ownable
      ✔ Should return the correct owner
      ✔ Owner should be able to transfer ownership
      ✔ Non-owner should not be able to transfer ownership
    Pausable
      ✔ Owner should be able to pause when NOT paused
      ✔ Owner should be able to unpause when already paused
      ✔ Owner should not be able to pause when already paused
      ✔ Owner should not be able to unpause when already unpaused
    read values
      ✔ Should return the correct auctionRepository
      ✔ Should return the correct asset
      ✔ Should return the correct startsAt
      ✔ Should return the correct endsAt
      ✔ Should return the correct highestBid so far
      ✔ Should return the correct highestBidder so far
    initialize
      ✔ Should fail if called
    Place Bid
      ✔ Should not be able to bid if paused
      ✔ Should not be able to bid before auction starts
      ✔ Should not be able to bid after auction ends
      ✔ Should not be able to bid if lesser than the highestBid so far
      ✔ Should be able to place bid
      ✔ Should not be able to bid in succession
      ✔ Should not be able to bid more than once
    Withdraw Bid
      ✔ Should not be able to withdraw bid if paused
      ✔ Should not be able to withdraw bid before auction starts
      After auction ends
        ✔ Should not be able to withdraw bid as only/highest bidder
        ✔ Should be able to withdraw bid when someone else is highest bidder
    claim Possession
      ✔ Should not be able to claim possession if paused
      ✔ Should not be able to claim possession before auction starts
      After auction ends
        ✔ Should be able to claim possession as only/highest bidder
        ✔ Should not be able to claim possession unless one is highest bidder
        ✔ Should be able to claim possession as highest bidder in case of multiple bids
        ✔ Should not be able to claim possession if already claimed
    Reclaim Asset
      ✔ Should not be able to reclaim asset if paused
      ✔ Should not be able to reclaim asset before auction starts
      ✔ Should not be able to reclaim asset if not original asset owner
      ✔ Should not be able to reclaim asset if bid is placed
      ✔ Should be able to reclaim asset if no bid is placed


  62 passing (7s)

-------------------------|----------|----------|----------|----------|----------------|
File                     |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
-------------------------|----------|----------|----------|----------|----------------|
 contracts/              |    88.78 |    81.25 |    81.48 |    89.22 |                |
  Auction.sol            |      100 |    93.33 |      100 |      100 |                |
  AuctionRepository.sol  |      100 |    84.62 |      100 |      100 |                |
  GenericERC20.sol       |       45 |       25 |    44.44 |       45 |... 60,62,86,91 |
 contracts/dependencies/ |      100 |       50 |      100 |      100 |                |
  CheckContract.sol      |      100 |       50 |      100 |      100 |                |
  ReentrancyGuard.sol    |      100 |       50 |      100 |      100 |                |
 contracts/interfaces/   |      100 |      100 |      100 |      100 |                |
  IAuction.sol           |      100 |      100 |      100 |      100 |                |
  IAuctionRepository.sol |      100 |      100 |      100 |      100 |                |
  IGenericERC20.sol      |      100 |      100 |      100 |      100 |                |
-------------------------|----------|----------|----------|----------|----------------|
All files                |    89.72 |    79.41 |    84.38 |    90.27 |                |
-------------------------|----------|----------|----------|----------|----------------|

> Istanbul reports written to ./coverage/ and ./coverage.json
✨  Done in 10.73s.
```

## Deployment

```console
❯ yarn deploy-local
yarn run v1.22.19
warning ../../../../package.json: No license field
$ hardhat run --network localhost deployment/deploy.ts
--
Asset SC deployed to:  0x5FbDB2315678afecb367f032d93F642f64180aa3
Asset contract deployed with txn hash: 0xdaab4900ff3a99fa09320b25d67d6a39e4f7a7d9b461d305ad55048b670ff4c5
--
Auction Repository SC deployed to:  0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
AuctionRepository SC deployed with txn hash: 0xb6eac1ea6c2f721cb6c0249543bab11c11dfc2aa9e4b29ba2ef17f9cd5eb5e7c
--
Auction SC deployed to:  0x4ED1B9f65065E8020967D86CB3453ec89aD4E929
Auction SC deployed with txn hash: 0x8c77fb469f5b0f6612abb1a239b63dbe6660eb7a0e6450c38cd2df160ecbe197
✨  Done in 2.07s.
```

## Contract size

```console
❯ yarn contract-size
yarn run v1.22.19
warning ../../../../package.json: No license field
$ hardhat size-contracts
Generating typings for: 15 artifacts in dir: ./build/typechain/ for target: ethers-v5
Successfully generated 46 typings!
Compiled 15 Solidity files successfully
 ·---------------------|--------------|----------------·
 |  Contract Name      ·  Size (KiB)  ·  Change (KiB)  │
 ······················|··············|·················
 |  console            ·       0.084  ·                │
 ······················|··············|·················
 |  ERC20              ·       2.131  ·                │
 ······················|··············|·················
 |  Auction            ·       3.738  ·                │
 ······················|··············|·················
 |  GenericERC20       ·       4.326  ·                │
 ······················|··············|·················
 |  AuctionRepository  ·       8.532  ·                │
 ·---------------------|--------------|----------------·
✨  Done in 3.93s.
```
