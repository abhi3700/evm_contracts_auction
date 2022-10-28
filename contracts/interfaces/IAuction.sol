// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Auction Contract.
 */
interface IAuction {
    function asset() external view returns (address);
    function creationTime() external view returns (uint256);
    function startsAt() external view returns (uint256);
    function endsAt() external view returns (uint256);
    function initialize(address _owner, address _originalAssetOwner, address _asset, uint256 _startsAt, uint256 _endsAt)
        external
        returns (bool);
    function bid() external payable;
    function withdraw() external returns (bool);
}
