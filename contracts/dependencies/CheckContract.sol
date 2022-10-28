// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// NOTE: type changed to abstract as not uploaded.
abstract contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view returns (bool) {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_account)
        }
        return (size != 0);
    }
}
