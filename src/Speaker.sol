// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L2_TO_L1_MESSENGER_SYSTEM_CONTRACT} from
    "lib/era-contracts/l1-contracts/contracts/common/l2-helpers/L2ContractAddresses.sol";

/// @title
/// @dev This contract is to be deployed on L2-A
contract Speaker {
    uint256 public value;

    function setValue(uint256 newValue) public {
        value = newValue;
        // The resulting `L2ToL1Log` will have as key `address(this)` and as value `keccak256(newValue)`
        L2_TO_L1_MESSENGER_SYSTEM_CONTRACT.sendToL1(abi.encode(newValue));
    }
}
