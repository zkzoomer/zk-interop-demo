// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {L2Message} from "lib/era-contracts/l1-contracts/contracts/common/Messaging.sol";

/// @title IHotPotato
/// @notice Interface for the `HotPotato` contract
interface IHotPotato is IERC721 {
    /// @notice Enum representing the status of a potato
    enum PotatoStatus {
        /// The potato has not been played, default state
        NotPlayed,
        /// The potato has been caught, thus cannot be caught again
        Caught,
        /// The potato has exploded, thus it cannot be thrown to another chain
        Exploded
    }

    /// @notice Event emitted when a potato is thrown to a destination chain
    event PotatoThrown(uint256 indexed potatoId, uint32 indexed recipientChainId);
    /// @notice Event emitted when a potato is caught on a destination chain
    event PotatoCaught(uint256 indexed potatoId);
    /// @notice Event emitted when a potato is caught on a destination chain, and its timebomb expires
    event PotatoExploded(uint256 indexed potatoId);

    /// @notice Thrown when the interop sender is not a player (a whitelisted `HotPotato` contract)
    error SenderIsNotPlayer();
    /// @notice Thrown when the potato was already played, ie, caught or exploded
    error PotatoWasPlayed();
    /// @notice Thrown when attempting to catch a potato from a chain other than the one it was thrown to
    error InvalidCatcher();
    /// @notice Thrown when the potato has already exploded, thus cannot be thrown to another chain
    error PotatoAlreadyExploded();
    /// @notice Thrown when the interop Merkle proof is invalid
    error InvalidInteropProof();

    /// @notice Sets a player (whitelisted `HotPotato` contract) for a ZK chain
    /// @param chainId The ZK Chain's chain ID
    /// @param player The whitelisted `HotPotato` contract address
    function setPlayer(uint256 chainId, address player) external;

    /// @notice Mints a new potato to the caller
    /// @return potatoId The ID of the minted potato
    function mintPotato() external returns (uint256);

    /// @notice Burns a potato and throws it to a catcher ZK Chain
    /// @param potatoId The ID of the potato to burn
    /// @param catcherChainId The chain ID of the catcher ZK Chain
    function burnAndThrowPotato(uint256 potatoId, uint32 catcherChainId) external;

    /// @notice Catches a potato by validating the interop message, and mints it to the caller
    /// @param throwerChainId The chain ID of the thrower ZK Chain
    /// @param batchNumber The executed batch number where the potato was thrown
    /// @param index The position in the L2 logs Merkle tree of the message that threw the potato
    /// @param message The message containing the potato ID that was thrown
    /// @param proof The Merkle proof for the interop message
    function catchAndMintPotato(
        uint256 throwerChainId,
        uint256 batchNumber,
        uint256 index,
        L2Message calldata message,
        bytes32[] calldata proof
    ) external;
}
