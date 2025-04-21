// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {
    L2_TO_L1_MESSENGER_SYSTEM_CONTRACT,
    L2_MESSAGE_VERIFICATION
} from "era-contracts/contracts/common/l2-helpers/L2ContractAddresses.sol";
import {L2Message} from "era-contracts/contracts/common/Messaging.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IHotPotato} from "./IHotPotato.sol";
import {PotatoLib} from "./PotatoLib.sol";

/// @title HotPotato
/// @notice A simple interop proof of concept for ZK Chains
contract HotPotato is IHotPotato, ERC721 {
    using PotatoLib for uint256;

    /// @notice The initial timebomb for a potato
    uint128 public constant initialTimebomb = type(uint128).max;
    /// @notice Timebomb decrease per interop message, in basis points
    uint128 public constant timebombDecrease = 9000;
    /// @notice The number of basis points in a whole
    uint256 public constant BPS = 10_000;

    /// @notice The number of potatoes minted in this contract
    uint32 public potatoCount;
    /// @notice Mapping from ZK Chain's chain ID to its whitelisted `HotPotato` contract address
    mapping(uint256 chainId => address player) public players;
    /// @notice Mapping from potato ID to its status
    mapping(uint256 potatoId => PotatoStatus status) public potatoes;

    constructor() ERC721("HotPotato", "HPT") {}

    /// @inheritdoc IHotPotato
    function mintPotato() external returns (uint256 potatoId) {
        potatoId = PotatoLib.getPotatoId(block.chainid, ++potatoCount, block.chainid, 0, initialTimebomb);
        _mint(msg.sender, potatoId);
    }

    /// @inheritdoc IHotPotato
    function burnAndThrowPotato(uint256 potatoId, uint32 catcherChainId) external returns (uint256 newPotatoId) {
        // The potato cannot have exploded
        if (potatoes[potatoId] == PotatoStatus.Exploded) {
            revert PotatoAlreadyExploded();
        }
        // Burn the potato token
        _burn(potatoId);
        // The Potato sent will have a different ID, as we update its recipient chain and decrease its timebomb
        newPotatoId = potatoId.setReceiverChainId(catcherChainId);
        uint256 newTimebomb = (potatoId.getTimebomb() * timebombDecrease) / BPS;
        newPotatoId = newPotatoId.setTimebomb(uint128(newTimebomb));
        // Send the potato to the recipient chain
        L2_TO_L1_MESSENGER_SYSTEM_CONTRACT.sendToL1(abi.encode(newPotatoId));
        emit PotatoThrown(newPotatoId, catcherChainId);
    }

    /// @inheritdoc IHotPotato
    function catchAndMintPotato(
        uint256 throwerChainId,
        uint256 batchNumber,
        uint256 index,
        L2Message calldata message,
        bytes32[] calldata proof
    ) external {
        // The message sender must be a `HotPotato` entity in a different ZK Chain
        // Since we deploy via CREATE2, this means the sender address must match that of this contract
        if (message.sender != address(this)) {
            revert SenderIsNotPlayer();
        }
        // The potato must not have been played
        uint256 potatoId = abi.decode(message.data, (uint256));
        if (potatoes[potatoId] != PotatoStatus.NotPlayed) {
            revert PotatoWasPlayed();
        }
        // The potato must have been thrown to the current chain
        if (potatoId.getReceiverChainId() != block.chainid) {
            revert InvalidCatcher();
        }

        // Validate message inclusion in senderChainId
        if (!L2_MESSAGE_VERIFICATION.proveL2MessageInclusionShared(throwerChainId, batchNumber, index, message, proof))
        {
            revert InvalidInteropProof();
        }

        // Mint new potato
        _mint(msg.sender, potatoId);

        // Timebomb check against random trigger
        uint256 trigger = uint256(keccak256(abi.encode(potatoId, block.timestamp))) & ((1 << 128) - 1); // last 128 bits
        if (potatoId.getTimebomb() < trigger) {
            // The potato has exploded and cannot be played again
            potatoes[potatoId] = PotatoStatus.Exploded;
            emit PotatoExploded(potatoId);
        } else {
            // The potato has been caught and can continue to be played
            potatoes[potatoId] = PotatoStatus.Caught;
            emit PotatoCaught(potatoId);
        }
    }
}
