// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import '../Errors.sol';

library SafeTransfer {
    bytes4 private constant TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TRANSFER_FROM =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFER, to, value)
        );

        // Revert with custom error if the transfer fails
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert TransferFailed();
        }
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFER_FROM, from, to, value)
        );

        // Revert with custom error if the transfer fails
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert TransferFailed();
        }
    }
}