// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./dependencies/CheckContract.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAuction.sol";
import "./Auction.sol";

/// @title A Auction Repository SC
/// @author abhi3700
/// @notice A Auction Repository SC
/// @dev A Auction Repository SC
contract AuctionRepository is Ownable, Pausable, CheckContract {
    // ==========State variables====================================
    mapping(address => address[]) public liveAuctions; // list of live auctions for an asset
    // mapping(address => address[]) public auctionHistory; // list of historic auctions for an asset
    mapping(address => address[]) public allAuctions; // list of all auctions for an asset

    // ==========Events====================================
    event AuctionCreated(address indexed auction, address indexed asset);

    // ==========Constructor====================================
    // ==========Functions====================================

    function createAuction(address _asset, uint256 _startsAt, uint256 _endsAt)
        external
        whenNotPaused
        returns (address auction)
    {
        require(checkContract(_asset), "Asset not a contract");
        require(_startsAt > block.timestamp, "startsAt > current time");
        require(_endsAt > _startsAt, "endsAt < startsAt");

        bytes memory bytecode = type(Auction).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_asset, _startsAt, _endsAt));
        assembly {
            auction := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IAuction(auction).initialize(_asset, _startsAt, _endsAt);

        liveAuctions[_asset].push(auction);
        allAuctions[_asset].push(auction);

        emit AuctionCreated(auction, _asset);
    }

    /// @notice should update the list of live auctions for an asset
    /// @dev delete from liveAuctions and add to auctionHistory array
    function updateLiveAuctions(address _asset, uint256 _arrcount) external onlyOwner {
        require(checkContract(_asset), "Asset not a contract");

        address[] memory auctions = liveAuctions[_asset];
        require(_arrcount <= auctions.length, "arrcount > liveAuctions.length");

        for (uint256 i = 0; i < _arrcount; ++i) {
            if (block.timestamp > IAuction(auctions[i]).endsAt() && checkContract(auctions[i])) {
                // auctionHistory[_asset].push(auctions[i]); // add to auctionHistory
                delete auctions[i]; // delete auction from liveAuctions
            }
        }

        liveAuctions[_asset] = auctions; // [a, b, c, d, e, f, g, h, , j, k, , , , o, p, , r, s, t] like array with missing values
    }

    /// @notice should rerun all the auctions active + completed i.e. all auctions
    /// @dev should rerun all the auctions active + completed i.e. all auctions
    /// @param _asset the asset for which the auctions are to be rerun
    function getAllAuctions(address _asset) external view returns (address[] memory auctions) {
        require(checkContract(_asset), "Asset not a contract");
        auctions = allAuctions[_asset];
    }

    /// @notice should return details of an auction
    /// @param _auctionContract the auction for which the details are to be returned
    function fetchAuction(address _auctionContract)
        external
        view
        returns (address asset, uint256 creationTime, uint256 startsAt, uint256 endsAt)
    {
        require(checkContract(_auctionContract), "Auction not a contract");
        asset = IAuction(_auctionContract).asset();
        creationTime = IAuction(_auctionContract).creationTime();
        startsAt = IAuction(_auctionContract).startsAt();
        endsAt = IAuction(_auctionContract).endsAt();
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
