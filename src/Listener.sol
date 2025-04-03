// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L2_MESSAGE_VERIFICATION} from
    "lib/era-contracts/l1-contracts/contracts/common/l2-helpers/L2ContractAddresses.sol";
import {L2Message} from "lib/era-contracts/l1-contracts/contracts/common/Messaging.sol";

/// @title
/// @dev This contract is to be deployed on a L2-B, which listens to Speaker changes on L2-A
contract Listener {
    /// @notice The chain ID of L2-A
    uint256 public immutable chainId;
    /// @notice The address of the Speaker contract on L2-A
    address public immutable speaker;

    uint256 public speakerValue;
    uint256 public lastBatch;

    error SenderIsNotSpeaker();
    error OldBatchNumber();
    error InvalidInclusionProof();

    constructor(uint256 _chainId, address _speaker) {
        chainId = _chainId;
        speaker = _speaker;
    }

    function listenToValue(
        uint256 _chainId,
        uint256 _batchNumber,
        uint256 _index,
        L2Message calldata _message,
        bytes32[] calldata _proof
    ) public {
        if (_message.sender != speaker) revert SenderIsNotSpeaker();
        if (_batchNumber < lastBatch) revert OldBatchNumber();
        if (!L2_MESSAGE_VERIFICATION.proveL2MessageInclusionShared(_chainId, _batchNumber, _index, _message, _proof)) {
            revert InvalidInclusionProof();
        }

        speakerValue = abi.decode(_message.data, (uint256));
        lastBatch = _batchNumber;
    }
}
