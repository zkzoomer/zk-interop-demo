// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {L2_MESSAGE_VERIFICATION} from "era-contracts/contracts/common/l2-helpers/L2ContractAddresses.sol";
import {IMessageVerification} from "era-contracts/contracts/state-transition/chain-interfaces/IMessageVerification.sol";
import {IL2ToL1Messenger} from "era-contracts/contracts/common/l2-helpers/IL2ToL1Messenger.sol";
import {L2Message} from "lib/era-contracts/l1-contracts/contracts/common/Messaging.sol";
import {IHotPotato} from "../src/IHotPotato.sol";
import {HotPotato} from "../src/HotPotato.sol";
import {PotatoLib} from "../src/PotatoLib.sol";

contract HotPotatoTest is Test {
    using PotatoLib for uint256;

    HotPotato hotPotato;

    function setUp() public {
        hotPotato = new HotPotato();
    }

    function test_mintPotato() public {
        uint256 potatoId = hotPotato.mintPotato();
        assertEq(potatoId, PotatoLib.getPotatoId(block.chainid, 1, block.chainid, 0, type(uint128).max));
        assertEq(hotPotato.balanceOf(address(this)), 1);
        assertEq(hotPotato.ownerOf(potatoId), address(this));
    }

    function test_burnAndThrowPotato_revertWhenPotatoAlreadyExploded() public {
        // First mint a potato
        uint256 potatoId = hotPotato.mintPotato();
        // Set the potato status to Exploded
        bytes32 slot = keccak256(abi.encode(potatoId, 8)); // 8 is the slot of the potatoes mapping
        vm.store(address(hotPotato), slot, bytes32(uint256(2)));
        // Now try to burn and throw the potato, which should revert
        vm.expectRevert(IHotPotato.PotatoAlreadyExploded.selector);
        hotPotato.burnAndThrowPotato(potatoId, uint32(block.chainid + 1));
    }

    function test_burnAndThrowPotato(uint32 catcherChainId) public {
        // First mint a potato
        uint256 potatoId = hotPotato.mintPotato();
        // Potato thrown will have a different ID
        uint256 newPotatoId = potatoId.setReceiverChainId(catcherChainId);
        uint256 newTimebomb = (potatoId.getTimebomb() * hotPotato.timebombDecrease()) / hotPotato.BPS();
        newPotatoId = newPotatoId.setTimebomb(uint128(newTimebomb));

        // Expect the L1MessageSent event
        vm.expectEmit(true, true, true, true);
        emit IL2ToL1Messenger.L1MessageSent(
            address(hotPotato), keccak256(abi.encode(newPotatoId)), abi.encode(newPotatoId)
        );
        // Expect the PotatoThrown event
        vm.expectEmit(true, true, true, true);
        emit IHotPotato.PotatoThrown(newPotatoId, catcherChainId);
        // Expect the L1MessageSent event
        hotPotato.burnAndThrowPotato(potatoId, catcherChainId);

        // Assert that the potato was indeed burned
        assertEq(hotPotato.balanceOf(address(this)), 0);
    }

    function test_catchAndMintPotato_revertWhenSenderNotWhitelisted(
        uint256 throwerChainId,
        uint256 batchNumber,
        uint256 index,
        address throwerAddress,
        uint256 potatoId,
        bytes32[] calldata proof
    ) public {
        vm.assume(throwerAddress != address(hotPotato));
        // Call reverts as the sender is not whitelisted
        vm.expectRevert(IHotPotato.SenderIsNotPlayer.selector);
        hotPotato.catchAndMintPotato(
            throwerChainId, batchNumber, index, L2Message(uint16(0), throwerAddress, abi.encode(potatoId)), proof
        );
    }

    function test_catchAndMintPotato_revertWhenPotatoWasPlayed(
        uint256 throwerChainId,
        uint256 batchNumber,
        uint256 index,
        uint256 potatoId,
        bytes32[] calldata proof
    ) public {
        // Set the potato status to Caught
        bytes32 slot = keccak256(abi.encode(potatoId, 8)); // 8 is the slot of the potatoes mapping
        vm.store(address(hotPotato), slot, bytes32(uint256(1)));
        // Call reverts as the potato was marked as played
        vm.expectRevert(IHotPotato.PotatoWasPlayed.selector);
        hotPotato.catchAndMintPotato(
            throwerChainId, batchNumber, index, L2Message(uint16(0), address(hotPotato), abi.encode(potatoId)), proof
        );
    }

    function test_catchAndMintPotato_revertWhenInvalidCatcher(
        uint256 throwerChainId,
        uint256 batchNumber,
        uint256 index,
        uint256 potatoId,
        bytes32[] calldata proof
    ) public {
        // Call reverts as the potato was sent to a different chain
        vm.expectRevert(IHotPotato.InvalidCatcher.selector);
        hotPotato.catchAndMintPotato(
            throwerChainId, batchNumber, index, L2Message(uint16(0), address(hotPotato), abi.encode(potatoId)), proof
        );
    }

    function test_catchAndMintPotato_revertWhenInvalidInteropProof(
        uint256 throwerChainId,
        uint256 batchNumber,
        uint256 index,
        uint256 potatoId,
        bytes32[] calldata proof
    ) public {
        potatoId = potatoId.setReceiverChainId(uint32(block.chainid));
        // Mock the message inclusion proof to be invalid
        mockMessageInclusion(
            throwerChainId,
            batchNumber,
            index,
            L2Message(uint16(0), address(hotPotato), abi.encode(potatoId)),
            proof,
            false
        );
        // Call reverts as the proof is invalid
        vm.expectRevert(IHotPotato.InvalidInteropProof.selector);
        hotPotato.catchAndMintPotato(
            throwerChainId, batchNumber, index, L2Message(uint16(0), address(hotPotato), abi.encode(potatoId)), proof
        );
    }

    function test_catchAndMintPotato_explodes(
        uint256 throwerChainId,
        uint256 batchNumber,
        uint256 index,
        uint256 potatoId,
        bytes32[] calldata proof
    ) public {
        potatoId = potatoId.setReceiverChainId(uint32(block.chainid));
        // Mock the message inclusion proof to be valid
        mockMessageInclusion(
            throwerChainId,
            batchNumber,
            index,
            L2Message(uint16(0), address(hotPotato), abi.encode(potatoId)),
            proof,
            true
        );

        // Force trigger to flip to exploded
        uint256 trigger = uint256(keccak256(abi.encode(potatoId, block.timestamp))) & ((1 << 128) - 1);
        vm.assume(potatoId.getTimebomb() < trigger);

        // Expect the PotatoExploded event
        vm.expectEmit(true, true, true, true);
        emit IHotPotato.PotatoExploded(potatoId);
        hotPotato.catchAndMintPotato(
            throwerChainId, batchNumber, index, L2Message(uint16(0), address(hotPotato), abi.encode(potatoId)), proof
        );

        // Potato is now exploded
        assertEq(uint8(hotPotato.potatoes(potatoId)), uint8(IHotPotato.PotatoStatus.Exploded));
        // New potato gets minted
        assertEq(hotPotato.balanceOf(address(this)), 1);
        assertEq(hotPotato.ownerOf(potatoId), address(this));
    }

    function test_catchAndMintPotato_caught(
        uint256 throwerChainId,
        uint256 batchNumber,
        uint256 index,
        uint256 potatoId,
        bytes32[] calldata proof
    ) public {
        potatoId = potatoId.setReceiverChainId(uint32(block.chainid));
        // Mock the message inclusion proof to be valid
        mockMessageInclusion(
            throwerChainId,
            batchNumber,
            index,
            L2Message(uint16(0), address(hotPotato), abi.encode(potatoId)),
            proof,
            true
        );

        // Force trigger to flip to caught
        uint256 trigger = uint256(keccak256(abi.encode(potatoId, block.timestamp))) & ((1 << 128) - 1);
        vm.assume(potatoId.getTimebomb() >= trigger);

        // Expect the PotatoCaught event
        vm.expectEmit(true, true, true, true);
        emit IHotPotato.PotatoCaught(potatoId);
        hotPotato.catchAndMintPotato(
            throwerChainId, batchNumber, index, L2Message(uint16(0), address(hotPotato), abi.encode(potatoId)), proof
        );

        // Potato is now caught
        assertEq(uint8(hotPotato.potatoes(potatoId)), uint8(IHotPotato.PotatoStatus.Caught));
        // New potato gets minted
        assertEq(hotPotato.balanceOf(address(this)), 1);
        assertEq(hotPotato.ownerOf(potatoId), address(this));
    }

    function mockMessageInclusion(
        uint256 throwerChainId,
        uint256 batchNumber,
        uint256 index,
        L2Message memory message,
        bytes32[] memory proof,
        bool isInclusionProofValid
    ) internal {
        vm.mockCall(
            address(L2_MESSAGE_VERIFICATION),
            abi.encodeWithSelector(
                IMessageVerification.proveL2MessageInclusionShared.selector,
                throwerChainId,
                batchNumber,
                index,
                message,
                proof
            ),
            abi.encode(isInclusionProofValid)
        );
    }
}
