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
    mapping(address => address[]) public liveAuctions;
    mapping(address => address[]) public auctionHistory;

    // ==========Events====================================
    event AuctionCreated(address indexed auction, address indexed asset);

    // ==========Functions====================================

    function createAuction(address _asset, uint256 _startsAt, uint256 _endsAt)
        external
        whenNotPaused
        returns (address auction)
    {
        checkContract(_asset);
        require(_startsAt > block.timestamp, "startsAt > creationTime");
        require(_endsAt > _startsAt, "endsAt < startsAt");

        // TODO: create a auction contract
        bytes memory bytecode = type(Auction).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_asset, _startsAt, _endsAt));
        assembly {
            auction := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IAuction(auction).initialize(_asset, _startsAt, _endsAt);

        liveAuctions[_asset].push(auction);
        auctionHistory[_asset].push(auction);

        emit AuctionCreated(auction, _asset);
    }

    /// @notice should rerun all the auctions active + completed
    /// @dev should rerun all the auctions active + completed
    /// @param _asset the asset for which the auctions are to be rerun
    function getAllAuctions(address _asset) external view returns (address[] memory auctions) {
        checkContract(_asset);
        auctions = auctionHistory[_asset];
    }

    /// @notice should return details of an auction
    /// @param _auctionContract the auction for which the details are to be returned
    function fetchAuction(address _auctionContract)
        external
        view
        returns (address asset, uint256 creationTime, uint256 startsAt, uint256 endsAt)
    {
        checkContract(_auctionContract);
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
