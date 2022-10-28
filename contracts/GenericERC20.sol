// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "hardhat/console.sol";

/// @title Generic ERC20 token
/// @author abhi3700
/// @notice This contract simulates a generic ERC20 token that is mintable and burnable and has a custom decimal
/// @dev This contract is important for DeFi SC codebase, where during unit test multiple tokens with different decimals is needed.
contract GenericERC20 is ERC20, Ownable, Pausable {
    // ==========State variables====================================
    uint8 private decimal;
    address public approvedOwnershipTo;

    // ==========Events=============================================
    event TokenMinted(address indexed toAcct, uint256 amount);
    event TokenBurnt(address indexed fromAcct, uint256 amount);

    // ==========Constructor========================================
    /**
     * @notice Deploy this contract with given name, symbol, and decimals
     * @dev the caller of this constructor will become the owner of this contract
     * @param _n name of this token
     * @param _s symbol of this token
     * @param _d number of decimals this token will be based on
     */
    constructor(string memory _n, string memory _s, uint8 _d) ERC20(_n, _s) {
        _setupDecimals(_d);
    }

    // ==========Modifiers==========================================

    // ==========Functions==========================================
    function _setupDecimals(uint8 _decimal) private returns (uint8) {
        decimal = _decimal;

        return decimal;
    }

    function decimals() public view override returns (uint8) {
        return decimal;
    }

    function mint(address _to, uint256 _amount) external onlyOwner whenNotPaused returns (bool) {
        require(_amount > 0, "amount must be positive");
        _mint(_to, _amount);

        emit TokenMinted(_to, _amount);

        return true;
    }

    function burn(uint256 _amount) external whenNotPaused returns (bool) {
        require(_amount > 0, "amount must be positive");
        _burn(msg.sender, _amount);

        emit TokenBurnt(msg.sender, _amount);

        return true;
    }

    function approveOwnership(address newOwner) external onlyOwner whenNotPaused returns (bool) {
        require(newOwner != address(0), "zero address");
        // console.log("approveOwnership called by %s for %s", msg.sender, newOwner);
        approvedOwnershipTo = newOwner;

        return true;
    }

    function transferFromOwnership(address newOwner) external whenNotPaused returns (bool) {
        require(msg.sender == approvedOwnershipTo, "Only approved address can call for transfer of ownership");
        // console.log("caller: %s", msg.sender);
        // console.log("Before: ownership transferred from: %s to: %s", owner(), newOwner);
        _transferOwnership(newOwner);
        // console.log("After: ownership transferred from: %s to: %s", owner(), newOwner);
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
