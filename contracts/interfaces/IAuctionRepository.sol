// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Auction Contract.
 */
interface IAuction {
    function createAuction(address _asset, uint256 _startsAt, uint256 _endsAt) external returns (address auction);
    function fetchAuction(address _auctionContract)
        external
        view
        returns (address asset, uint256 creationTime, uint256 startsAt, uint256 endsAt);
    function getAllAuctions(address _asset) external view returns (address[] memory auctions);
    function getLiveAuctions(address _asset) external view returns (address[] memory auctions);
}
