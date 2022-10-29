// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./dependencies/CheckContract.sol";
import "./interfaces/IGenericERC20.sol";
import "./interfaces/IAuction.sol";
import "./Auction.sol";
import "./dependencies/ReentrancyGuard.sol";
// import "hardhat/console.sol";

/// @title A Auction Repository SC
/// @author abhi3700
/// @notice A Auction Repository SC
/// @dev A Auction Repository SC
contract AuctionRepository is Ownable, Pausable, CheckContract, ReentrancyGuard {
    // ==========State variables====================================
    // NOTE: for ERC20, 1 asset can have only 1 auction.
    // But, for NFT standards like ERC721, 1 asset can have multiple auctions with unique token ids.
    mapping(address => address[]) public liveAuctions; // list of live auctions for an asset
    // mapping(address => address[]) public auctionHistory; // list of historic auctions for an asset
    mapping(address => address[]) public allAuctions; // list of all auctions for an asset

    // ==========Events====================================
    event AuctionCreated(address indexed auction, address indexed asset);

    // ==========Constructor====================================
    // ==========Functions====================================

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param _asset The address of the asset
    /// @param _startsAt The start time of the auction
    /// @param _endsAt The timestamp at which the auction ends
    /// @return auction address of the newly created auction
    function createAuction(address _asset, uint256 _startsAt, uint256 _endsAt)
        external
        whenNotPaused
        nonReentrant
        returns (address auction)
    {
        require(checkContract(_asset), "Asset not a contract");
        require(IGenericERC20(_asset).owner() == msg.sender, "Only asset owner can create auction");
        require(_startsAt > block.timestamp, "startsAt < now");
        require(_endsAt > _startsAt, "endsAt < startsAt");
        require(liveAuctions[_asset].length == 0, "Auction already exists");
        require(
            IGenericERC20(_asset).approvedOwnershipTo() == address(this), "AuctionRepository not approved for ownership"
        );

        bytes memory bytecode = type(Auction).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_asset, _startsAt, _endsAt));
        assembly {
            auction := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // console.log("Auction created: %s", auction);
        IAuction(auction).initialize(owner(), msg.sender, _asset, _startsAt, _endsAt);

        liveAuctions[_asset].push(auction);
        allAuctions[_asset].push(auction);

        emit AuctionCreated(auction, _asset);

        // transfer ownership of the auction to the Auction contract created
        bool success = IGenericERC20(_asset).transferFromOwnership(auction);
        require(success, "transferFromOwnership failed");
    }

    /// @notice should update the list of live auctions for an asset by removing the auction address which is ended
    /// @dev only delete from liveAuctions & set the liveAuctions to new array obtained
    /// @param _asset address of the asset
    /// @param _loopCount loop count for gas optimization
    function updateLiveAuctions(address _asset, uint256 _loopCount) external onlyOwner whenNotPaused {
        require(checkContract(_asset), "Asset not a contract");

        address[] memory auctions = liveAuctions[_asset];
        require(_loopCount <= auctions.length, "loopCount > liveAuctions.length");

        for (uint256 i = 0; i < _loopCount; ++i) {
            if (block.timestamp > IAuction(auctions[i]).endsAt() && checkContract(auctions[i])) {
                //// auctionHistory[_asset].push(auctions[i]); // add to auctionHistory
                delete auctions[i]; // delete auction from liveAuctions
            }
        }

        liveAuctions[_asset] = auctions; // [a, b, c, d, e, f, g, h, , j, k, , , , o, p, , r, s, t] like array with missing values
    }

    /// @notice should rerun all the auctions active + completed i.e. all auctions
    /// @dev should rerun all the auctions active + completed i.e. all auctions
    /// @param _asset the asset for which the auctions are to be rerun
    /// @return auctions array of all the auctions for the asset
    function getAllAuctions(address _asset) external view returns (address[] memory auctions) {
        require(checkContract(_asset), "Asset not a contract");
        auctions = allAuctions[_asset];
    }

    /// @notice should rerun all the auctions active
    /// @dev should rerun all the auctions active
    /// @param _asset the asset for which the live auctions are to be rerun
    /// @return auctions array of all the live auctions for the asset
    function getLiveAuctions(address _asset) external view returns (address[] memory auctions) {
        require(checkContract(_asset), "Asset not a contract");
        auctions = liveAuctions[_asset];
    }

    /// @notice should return details of an auction
    /// @param _auctionContract the auction for which the details are to be returned
    function fetchAuction(address _auctionContract)
        external
        view
        returns (address asset, address originalAssetOwner, uint256 creationTime, uint256 startsAt, uint256 endsAt)
    {
        require(checkContract(_auctionContract), "Auction not a contract");
        asset = IAuction(_auctionContract).asset();
        creationTime = IAuction(_auctionContract).creationTime();
        startsAt = IAuction(_auctionContract).startsAt();
        endsAt = IAuction(_auctionContract).endsAt();
        originalAssetOwner = IAuction(_auctionContract).originalAssetOwner();
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
